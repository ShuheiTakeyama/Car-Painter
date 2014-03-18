Shader "ShaderMan/CarPaintGL" {
	Properties 
	{
		_DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
		_SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
		_SpecularPower ("Specular Power", Range (0.0, 64.0)) = 16.0
		_AmbientColor ("Ambient Color", Color) = (0, 0, 0, 0)
		
		// Add for CubeMapping
		_EnvironmentMap ("Environment Map", CUBE) = "" {}
		_MixRatio ("Mix Ratio", Range (0.0, 1.0)) = 0.5
		
		// Add for fresnel
		_FresnelScale ("Fresnel Scale", Range (0.0, 1.0)) = 0.1
		_FresnelExponent ("Fresnel Exponent", Range (0.001, 5.0)) = 5.0
		
		// Add for normal mapping
		_NormalMap ("Normal Map", 2D) = "bump" {}
		
		// Add for car paint
		_PaintColor1 ("Paint Color 1", Color) = (1, 1, 1, 1)
		_PaintColor2 ("Paint Color 2", Color) = (1, 1, 1, 1)
		_PaintColor3 ("Paint Color 3", Color) = (1, 1, 1, 1)
		_FlakesColor ("Flakes Color", Color) = (1, 1, 1, 1)
		_FlakesNormalMap ("Flakes Normal Map", 2D) = "bump" {}
		_FlakesPerturbation1 ("Flakes Perturbation 1", Range (0.0, 1.0)) = 0.2
		_NormalPerturbation ("Normal Perturbation", Range (0.0, 1.0)) = 1.0
		_FlakesPerturbation2 ("Flakes Perturbation 2", Range (0.0, 1.0)) = 1.0
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
			
			uniform vec4 _DiffuseColor;
			uniform vec4 _SpecularColor;
			uniform float _SpecularPower;
			uniform vec4 _AmbientColor;
			uniform samplerCube _EnvironmentMap;
			uniform float _MixRatio;
			uniform float _FresnelScale;
			uniform float _FresnelExponent;
			uniform sampler2D _NormalMap;
			uniform vec4 _NormalMap_ST;
			uniform vec4 _PaintColor1;
			uniform vec4 _PaintColor2;
			uniform vec4 _PaintColor3;
			uniform vec4 _FlakesColor;
			uniform sampler2D _FlakesNormalMap;
			uniform vec4 _FlakesNormalMap_ST;
			uniform float _FlakesPerturbation1;
			uniform float _NormalPerturbation;
			uniform float _FlakesPerturbation2;
		
			uniform mat4 _Object2World;
			uniform mat4 _World2Object;
			uniform vec3 _WorldSpaceCameraPos;
			uniform vec4 _WorldSpaceLightPos0;
			uniform vec4 _LightColor0;
						
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
				gl_TexCoord[1] = gl_MultiTexCoord1;
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
				
				encodedNormal = texture2D (_FlakesNormalMap, gl_TexCoord[1].xy * _FlakesNormalMap_ST.xy + _FlakesNormalMap_ST.zw);
				vec3 flakesNormalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				flakesNormalDirection.z = sqrt (1.0 - dot (flakesNormalDirection, flakesNormalDirection));
				flakesNormalDirection = normalize (localSurface2World * flakesNormalDirection);
				
				// Compute surface normal for first layer
				vec3 surfaceNormal = _FlakesPerturbation1 * flakesNormalDirection + _NormalPerturbation * normalDirection;

				// Compute surface normal for second layer
				vec3 subsurfaceNormal = _FlakesPerturbation2 * (flakesNormalDirection + normalDirection);

				// Get view direction
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldSpacePosition));
				
				// Compute surface fresnel
				float surfaceFresnel = clamp ((dot (surfaceNormal, viewDirection)), 0.0, 1.0);

				// Compute subsurface fresnel
				float subsurfaceFresnel = clamp ((dot (subsurfaceNormal, viewDirection)), 0.0, 1.0);

				// Calculate paint color
				float surfaceFresnelSq = surfaceFresnel * surfaceFresnel;
				
				vec4 paintColor;
				paintColor += _PaintColor1 * surfaceFresnel;
				paintColor += _PaintColor2 * surfaceFresnelSq;
				paintColor += _PaintColor3 * surfaceFresnelSq * surfaceFresnelSq;
				paintColor += _FlakesColor * pow (subsurfaceFresnel, 16.0);

				// Get light direction and attenuation
				vec3 lightDirection;
				float attenuation;
								
				if (0.0 == _WorldSpaceLightPos0.w)
				{
					attenuation = 1.0;
					lightDirection = normalize (vec3 (_WorldSpaceLightPos0));
				}
				else
				{
					lightDirection = vec3 (_WorldSpaceLightPos0 - WorldSpacePosition);
					float distance = length (lightDirection);
					attenuation = 1.0 / distance;
					lightDirection = normalize (lightDirection);
				}

				// Calculate diffuse
				float diffuse = max (0.0, dot (normalDirection, lightDirection));

				// Calculate specular
				float specular = 0.0;
				if (diffuse > 0.0)
				{
					specular = pow (max (0.0, dot (reflect (-lightDirection, normalDirection), viewDirection)), _SpecularPower);
				}

				// Calculate base color
				vec4 color;
				color = _AmbientColor;
				color += attenuation * _LightColor0 * _DiffuseColor * paintColor * diffuse;
				color += attenuation * _LightColor0 * _SpecularColor * specular;
				
				// Look up environment map value in cube map
				vec3 reflectedDirection = reflect (-viewDirection, normalDirection);
				vec4 environmentColor = textureCube (_EnvironmentMap, reflectedDirection);

				// "Fresnel" attenuates strength of reflection (According to Fresnel's law)
			    float fresnelMin = _FresnelScale * _MixRatio;
			    float fresnelCos = dot (viewDirection, normalDirection);
			    float mixRatioOnFresnel = fresnelMin + (_MixRatio - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);
			    
				// Mix!
				color = mix (color, environmentColor, mixRatioOnFresnel);
				
				gl_FragColor = color;
			}
			
			#endif
			
			ENDGLSL
		}
		
		Pass
		{
			Tags
			{ 
				"LightMode" = "ForwardAdd" 
			}
			
			Blend One One
			
			GLSLPROGRAM
			
			uniform vec4 _DiffuseColor;
			uniform vec4 _SpecularColor;
			uniform float _SpecularPower;
			uniform vec4 _AmbientColor;
			uniform samplerCube _EnvironmentMap;
			uniform float _MixRatio;
			uniform float _FresnelScale;
			uniform float _FresnelExponent;
			uniform sampler2D _NormalMap;
			uniform vec4 _NormalMap_ST;
			uniform vec4 _PaintColor1;
			uniform vec4 _PaintColor2;
			uniform vec4 _PaintColor3;
			uniform vec4 _FlakesColor;
			uniform sampler2D _FlakesNormalMap;
			uniform vec4 _FlakesNormalMap_ST;
			uniform float _FlakesPerturbation1;
			uniform float _NormalPerturbation;
			uniform float _FlakesPerturbation2;
		
			uniform mat4 _Object2World;
			uniform mat4 _World2Object;
			uniform vec3 _WorldSpaceCameraPos;
			uniform vec4 _WorldSpaceLightPos0;
			uniform vec4 _LightColor0;
						
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
				gl_TexCoord[1] = gl_MultiTexCoord1;
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
				
				encodedNormal = texture2D (_FlakesNormalMap, gl_TexCoord[1].xy * _FlakesNormalMap_ST.xy + _FlakesNormalMap_ST.zw);
				vec3 flakesNormalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				flakesNormalDirection.z = sqrt (1.0 - dot (flakesNormalDirection, flakesNormalDirection));
				flakesNormalDirection = normalize (localSurface2World * flakesNormalDirection);
				
				// Compute surface normal for first layer
				vec3 surfaceNormal = _FlakesPerturbation1 * flakesNormalDirection + _NormalPerturbation * normalDirection;

				// Compute surface normal for second layer
				vec3 subsurfaceNormal = _FlakesPerturbation2 * (flakesNormalDirection + normalDirection);

				// Get view direction
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldSpacePosition));
				
				// Compute surface fresnel
				float surfaceFresnel = clamp ((dot (surfaceNormal, viewDirection)), 0.0, 1.0);

				// Compute subsurface fresnel
				float subsurfaceFresnel = clamp ((dot (subsurfaceNormal, viewDirection)), 0.0, 1.0);

				// Calculate paint color
				float surfaceFresnelSq = surfaceFresnel * surfaceFresnel;
				
				vec4 paintColor;
				paintColor += _PaintColor1 * surfaceFresnel;
				paintColor += _PaintColor2 * surfaceFresnelSq;
				paintColor += _PaintColor3 * surfaceFresnelSq * surfaceFresnelSq;
				paintColor += _FlakesColor * pow (subsurfaceFresnel, 16.0);

				// Get light direction and attenuation
				vec3 lightDirection;
				float attenuation;
								
				if (0.0 == _WorldSpaceLightPos0.w)
				{
					attenuation = 1.0;
					lightDirection = normalize (vec3 (_WorldSpaceLightPos0));
				}
				else
				{
					lightDirection = vec3 (_WorldSpaceLightPos0 - WorldSpacePosition);
					float distance = length (lightDirection);
					attenuation = 1.0 / distance;
					lightDirection = normalize (lightDirection);
				}

				// Calculate diffuse
				float diffuse = max (0.0, dot (normalDirection, lightDirection));

				// Calculate specular
				float specular = 0.0;
				if (diffuse > 0.0)
				{
					specular = pow (max (0.0, dot (reflect (-lightDirection, normalDirection), viewDirection)), _SpecularPower);
				}

				// Calculate base color
				vec4 color;
				color = _AmbientColor;
				color += attenuation * _LightColor0 * _DiffuseColor * paintColor * diffuse;
				color += attenuation * _LightColor0 * _SpecularColor * specular;
				
				// Look up environment map value in cube map
				vec3 reflectedDirection = reflect (-viewDirection, normalDirection);
				vec4 environmentColor = textureCube (_EnvironmentMap, reflectedDirection);

				// "Fresnel" attenuates strength of reflection (According to Fresnel's law)
			    float fresnelMin = _FresnelScale * _MixRatio;
			    float fresnelCos = dot (viewDirection, normalDirection);
			    float mixRatioOnFresnel = fresnelMin + (_MixRatio - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);
			    
				// Mix!
				color = mix (color, environmentColor, mixRatioOnFresnel);
				
				gl_FragColor = color;
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}

