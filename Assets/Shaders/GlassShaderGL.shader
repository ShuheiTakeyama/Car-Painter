Shader "ShaderMan/GlassShaderGL" 
{
	Properties 
	{
		_BaseColor ("Base Color", Color) = (1, 1, 1, 1)
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_Scale ("Scale", Vector) = (0.05, 0.05, 0.0, 0.0)
		_RefractionMap ("Refraction Map", 2D) = "white" {}
		_ReflectionMap ("Reflection Map", CUBE) = "" {}
		_Reflectivity ("Reflectivity", Range (0.0, 1.0)) = 0.5
		_FresnelScale ("Fresnel Scale", Range (0.0, 1.0)) = 0.1
		_FresnelExponent ("Fresnel Exponent", Range (0.001, 5.0)) = 5.0
	}
	
	SubShader 
	{
		Tags
		{
			"Queue" = "Transparent"
		}
			
		Pass
		{
			ZWrite Off
         	Blend SrcAlpha OneMinusSrcAlpha

			GLSLPROGRAM

			uniform vec4 _BaseColor;
			uniform sampler2D _NormalMap;
			uniform vec4 _NormalMap_ST;
			uniform vec4 _Scale;
			uniform sampler2D _RefractionMap;
			uniform vec4 _RefractionMap_ST;
			uniform samplerCube _ReflectionMap;
			uniform float _Reflectivity;
			uniform float _FresnelScale;
			uniform float _FresnelExponent;

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
				vec3 normalMapColor = vec3 (2.0 * encodedNormalMapColor.ag - vec2 (1.0), 0.0);
				normalMapColor.z = sqrt (1.0 - dot (normalMapColor, normalMapColor));
				normalMapColor = normalize (normalMapColor);
				
				// Displace texture coordinates
				vec2 newTextureCoordinates = gl_FragCoord.xy / _ScreenParams.xy + normalMapColor.xy * _Scale.xy;
				
				// Sample refraction map
				vec4 refractionColor = texture2D (_RefractionMap, newTextureCoordinates * _RefractionMap_ST.xy + _RefractionMap_ST.zw);

				// Sample reflection map
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
				vec4 reflectionColor = textureCube (_ReflectionMap, reflectedDirection);

				// Final Color
			    float fresnelMin = _FresnelScale * _Reflectivity;
			    float fresnelCos = dot (viewDirection, normalDirection);
			    float ratioOnFresnel = fresnelMin + (_Reflectivity - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);

				gl_FragColor = _BaseColor * mix (refractionColor, reflectionColor, ratioOnFresnel);
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}

