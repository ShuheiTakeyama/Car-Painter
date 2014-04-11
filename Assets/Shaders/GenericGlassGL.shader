Shader "ShaderMan/GenericGlassGL" 
{
	Properties 
	{
		_BaseColor ("Base Color", Color) = (1, 1, 1, 1)
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_Scale ("Scale", Vector) = (0.05, 0.05, 0.0, 0.0)
		_RefractionMap ("Refraction Map", 2D) = "white" {}
		_DiffuseEnvironmentMap ("Diffuse Environment Map", CUBE) = "" {}
		_DiffusePercent ("Diffuse Percent", Range (0.0, 1.0)) = 1.0
		_SpecularEnvironmentMap ("Specular Environment Map", CUBE) = "" {}
		_SpecularPercent ("Specular Percent", Range (0.0, 1.0)) = 1.0
		_FresnelScale ("Fresnel Scale", Range (0.0, 1.0)) = 0.1
		_FresnelExponent ("Fresnel Exponent", Range (0.001, 5.0)) = 5.0
		_Brightness ("Brightness", Range (0.0, 2.0)) = 1.0
		_AverageLuminance ("Average Luminance", Color) = (0.5, 0.5, 0.5, 1.0)
		_Contrast ("Contrast", Range (0.0, 2.0)) = 1.0
	}
	
	SubShader 
	{
		Tags
		{
			"Queue" = "Transparent"
		}
			
		Pass
		{
			GLSLPROGRAM

			uniform vec4 _BaseColor;
			uniform sampler2D _NormalMap;
			uniform vec4 _NormalMap_ST;
			uniform vec4 _Scale;
			uniform sampler2D _RefractionMap;
			uniform vec4 _RefractionMap_ST;
			uniform samplerCube _DiffuseEnvironmentMap;
			uniform float _DiffusePercent;
			uniform samplerCube _SpecularEnvironmentMap;
			uniform float _SpecularPercent;
			uniform float _FresnelScale;
			uniform float _FresnelExponent;
			uniform float _Brightness;
			uniform vec4 _AverageLuminance;
			uniform float _Contrast;

			uniform mat4 _Object2World;
			uniform mat4 _World2Object;
			uniform vec3 _WorldSpaceCameraPos;
			uniform vec4 _ScreenParams;

			varying vec4 WorldSpacePosition;
			
			varying vec3 WorldSpaceTangent;
			varying vec3 WorldSpaceNormal;
			varying vec3 WorldSpaceBinormal;
			
			#ifdef VERTEX
			
			attribute vec4 Tangent;
			
			void main ()
			{
				WorldSpacePosition = _Object2World * gl_Vertex;
							
				WorldSpaceTangent = normalize (vec3 (_Object2World * vec4 (vec3 (Tangent), 0.0)));
				WorldSpaceNormal = normalize (vec3 (vec4 (gl_Normal, 0.0) * _World2Object));
				WorldSpaceBinormal = normalize (cross (WorldSpaceNormal, WorldSpaceTangent) * Tangent.w);

				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				gl_TexCoord[0] = gl_MultiTexCoord0;
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{
				// Sample normal map
				vec4 encodedNormalMapColor = texture2D (_NormalMap, gl_TexCoord[0].xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
//				vec3 normalMapColor = vec3 (2.0 * encodedNormalMapColor.ag - vec2 (1.0), 0.0);
//				normalMapColor.z = sqrt (1.0 - dot (normalMapColor, normalMapColor));
//				normalMapColor = normalize (normalMapColor);
				vec3 normalMapColor = 2.0 * encodedNormalMapColor.rgb - 1.0;
				
				// Displace texture coordinates
				vec2 newTextureCoordinates = gl_FragCoord.xy / _ScreenParams.xy + normalMapColor.xy * _Scale.xy;
				
				// Sample refraction map
				vec4 refractionColor = texture2D (_RefractionMap, newTextureCoordinates * _RefractionMap_ST.xy + _RefractionMap_ST.zw);

				// Sample environment maps
				vec3 tangent = normalize (WorldSpaceTangent);
				vec3 normal = normalize (WorldSpaceNormal);
				vec3 binormal = normalize (WorldSpaceBinormal);

				mat3 localSurface2World;
            	localSurface2World[0] = tangent;
            	localSurface2World[1] = binormal;
            	localSurface2World[2] = normal;

				vec3 normalDirection = normalize (localSurface2World * normalMapColor);
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldSpacePosition));
				vec3 reflectedDirection = reflect (-viewDirection, normalDirection);
				
				vec4 diffuseEnvironmentColor = textureCube (_DiffuseEnvironmentMap, normalDirection);
				diffuseEnvironmentColor *= _Brightness;
				diffuseEnvironmentColor = mix (_AverageLuminance, diffuseEnvironmentColor, _Contrast);
				vec4 specularEnvironmentColor = textureCube (_SpecularEnvironmentMap, reflectedDirection);
				specularEnvironmentColor *= _Brightness;
				specularEnvironmentColor = mix (_AverageLuminance, specularEnvironmentColor, _Contrast);

				// Final Color
			    float fresnelMin = _FresnelScale * _SpecularPercent;
			    float fresnelCos = dot (viewDirection, normalDirection);
			    float _SpecularPercentOnFresnel = fresnelMin + (_SpecularPercent - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);

				vec4 finalColor;
				finalColor = _BaseColor * refractionColor * (1.0 - _SpecularPercentOnFresnel);
				finalColor = mix (finalColor, finalColor * diffuseEnvironmentColor, _DiffusePercent);
				finalColor = mix (finalColor, finalColor + specularEnvironmentColor * _SpecularPercentOnFresnel, _SpecularPercentOnFresnel);

				gl_FragColor = finalColor;
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}

