Shader "ShaderMan/CarPaint" 
{
	Properties 
	{
		_PaintColor1 ("Paint Color 1", Color) = (1, 1, 1, 1)
		_PaintColor2 ("Paint Color 2", Color) = (1, 1, 1, 1)
		_PaintColor3 ("Paint Color 3", Color) = (1, 1, 1, 1)
		_FlakesColor ("Flakes Color", Color) = (1, 1, 1, 1)
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_FlakesNormalMap ("Flakes Normal Map", 2D) = "bump" {}
		_FlakesPerturbation1 ("Flakes Perturbation 1", Range (0.0, 1.0)) = 0.2
		_NormalPerturbation ("Normal Perturbation", Range (0.0, 1.0)) = 1.0
		_FlakesPerturbation2 ("Flakes Perturbation 2", Range (0.0, 1.0)) = 1.0

		_DiffuseEnvironmentMap ("Diffuse Environment Map", CUBE) = "" {}
		_DiffusePercent ("Diffuse Percent", Range (0.0, 1.0)) = 1.0
		_SpecularEnvironmentMap ("Specular Environment Map", CUBE) = "" {}
		_SpecularPercent ("Specular Percent", Range (0.0, 1.0)) = 1.0

		_FresnelScale ("Fresnel Scale", Range (0.0, 1.0)) = 0.1
		_FresnelExponent ("Fresnel Exponent", Range (0.001, 5.0)) = 5.0

		_Brightness ("Brightness", Range (0.0, 2.0)) = 1.0
		_AverageLuminance ("Average Luminance", Color) = (0.5, 0.5, 0.5, 1.0)
		_Contrast ("Contrast", Range (0.0, 2.0)) = 1.0
		
		_AmbientOcclusionMap ("Ambient Occlusion Map", 2D) = "white" {}
	}
	
	SubShader 
	{
		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}
			
			GLSLPROGRAM

			uniform vec4 _PaintColor1;
			uniform vec4 _PaintColor2;
			uniform vec4 _PaintColor3;
			uniform vec4 _FlakesColor;
			uniform sampler2D _NormalMap;
			uniform vec4 _NormalMap_ST;
			uniform sampler2D _FlakesNormalMap;
			uniform vec4 _FlakesNormalMap_ST;
			uniform float _FlakesPerturbation1;
			uniform float _NormalPerturbation;
			uniform float _FlakesPerturbation2;

			uniform samplerCube _DiffuseEnvironmentMap;
			uniform float _DiffusePercent;
			uniform samplerCube _SpecularEnvironmentMap;
			uniform float _SpecularPercent;

			uniform float _FresnelScale;
			uniform float _FresnelExponent;
			
			uniform float _Brightness;
			uniform vec4 _AverageLuminance;
			uniform float _Contrast;

			uniform sampler2D _AmbientOcclusionMap;
			
			uniform mat4 _Object2World;
			uniform mat4 _World2Object;
			uniform vec3 _WorldSpaceCameraPos;
			uniform vec4 _WorldSpaceLightPos0;
						
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
				// Build local surface to world space matrix
				vec3 tangent = normalize (WorldSpaceTangent);
				vec3 normal = normalize (WorldSpaceNormal);
				vec3 binormal = normalize (WorldSpaceBinormal);

				mat3 localSurface2World;
            	localSurface2World[0] = tangent;
            	localSurface2World[1] = binormal;
            	localSurface2World[2] = normal;

				// Sample normal maps
				vec4 encodedNormal;
				
				encodedNormal = texture2D (_NormalMap, gl_TexCoord[0].xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				vec3 normalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				normalDirection.z = sqrt (1.0 - dot (normalDirection, normalDirection));
				normalDirection = normalize (localSurface2World * normalDirection);
				
				encodedNormal = texture2D (_FlakesNormalMap, gl_TexCoord[0].xy * _FlakesNormalMap_ST.xy + _FlakesNormalMap_ST.zw);
				vec3 flakesNormalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				flakesNormalDirection.z = sqrt (1.0 - dot (flakesNormalDirection, flakesNormalDirection));
				flakesNormalDirection = normalize (localSurface2World * flakesNormalDirection);
				
				// Compute surface and subsurface normal
				vec3 surfaceNormal = _FlakesPerturbation1 * flakesNormalDirection + _NormalPerturbation * normalDirection;
				vec3 subsurfaceNormal = _FlakesPerturbation2 * (flakesNormalDirection + normalDirection);

				// Get view direction
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldSpacePosition));
				
				// Compute surface and subsurface fresnel
				float surfaceFresnel = clamp ((dot (surfaceNormal, viewDirection)), 0.0, 1.0);
				float subsurfaceFresnel = clamp ((dot (subsurfaceNormal, viewDirection)), 0.0, 1.0);

				// Calculate paint color
				float surfaceFresnelSq = surfaceFresnel * surfaceFresnel;
				
				gl_FragColor = vec4 (flakesNormalDirection, 1.0);
				
//				vec4 paintColor;
//				paintColor += _PaintColor1 * surfaceFresnel;
//				paintColor += _PaintColor2 * surfaceFresnelSq;
//				paintColor += _PaintColor3 * surfaceFresnelSq * surfaceFresnelSq;
//				paintColor += _FlakesColor * pow (subsurfaceFresnel, 16.0);

//				// Sampler environment maps
//				vec3 reflectedDirection = reflect (-viewDirection, normalDirection);
//				
//				vec4 diffuseEnvironmentColor = textureCube (_DiffuseEnvironmentMap, normalDirection);
//				diffuseEnvironmentColor *= _Brightness;
//				diffuseEnvironmentColor = mix (_AverageLuminance, diffuseEnvironmentColor, _Contrast);
//				vec4 specularEnvironmentColor = textureCube (_SpecularEnvironmentMap, reflectedDirection);
//				specularEnvironmentColor *= _Brightness;
//				specularEnvironmentColor = mix (_AverageLuminance, specularEnvironmentColor, _Contrast);
//				
//				// "Fresnel" attenuates strength of reflection (According to Fresnel's law)
//			    float fresnelMin = _FresnelScale * _SpecularPercent;
//			    float fresnelCos = dot (viewDirection, normalDirection);
//			    float mixRatioOnFresnel = fresnelMin + (_SpecularPercent - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);
//				
//				// Sample ambient occlusion map
//				float accessibility = texture2D (_AmbientOcclusionMap, gl_TexCoord[0].xy).a;
//
//				// Final color
//				vec4 color;
//				color = mix (paintColor, paintColor * diffuseEnvironmentColor, _DiffusePercent);
//				color *= accessibility;
//				color = mix (color, color + specularEnvironmentColor, mixRatioOnFresnel);
//				
//				gl_FragColor = color;
//				gl_FragColor = paintColor;
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}
