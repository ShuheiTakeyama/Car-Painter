Shader "ShaderMan/NormalMappingGL" {
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
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{				
				vec3 tangent = normalize (WorldSpaceTangent);
				vec3 normal = normalize (WorldSpaceNormal);
				vec3 binormal = normalize (WorldSpaceBinormal);

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

				// Get view direction
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldSpacePosition));
				
				// Build local surface to world space matrix
				mat3 localSurface2World;
            	localSurface2World[0] = tangent;
            	localSurface2World[1] = binormal;
            	localSurface2World[2] = normal;
				
				// Sample normal map
				vec4 encodedNormal = texture2D (_NormalMap, gl_TexCoord[0].xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				vec3 normalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				normalDirection.z = sqrt (1.0 - dot (normalDirection, normalDirection));
				normalDirection = normalize (localSurface2World * normalDirection);
				
				// Calculate diffuse
				float diffuse = max (0.0, dot (normalDirection, lightDirection));

				// Calculate specular
				float specular = 0.0;
				if (diffuse > 0.0)
				{
					specular = pow (max (0.0, dot (reflect (-lightDirection, normalDirection), viewDirection)), _SpecularPower);
				}

				// Calculate base color
				vec3 color;
				color = vec3 (_AmbientColor);
				color += attenuation * vec3 (_LightColor0) * vec3 (_DiffuseColor) * diffuse;
				color += attenuation * vec3 (_LightColor0) * vec3 (_SpecularColor) * specular;
				
				// Look up environment map value in cube map
				vec3 reflectedDirection = reflect (-viewDirection, normalDirection);
				vec3 environmentColor = vec3 (textureCube (_EnvironmentMap, reflectedDirection));

				// "Fresnel" attenuates strength of reflection (According to Fresnel's law)
			    float fresnelMin = _FresnelScale * _MixRatio;
			    float fresnelCos = dot (viewDirection, normalDirection);
			    float mixRatioOnFresnel = fresnelMin + (_MixRatio - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);
			    
				// Mix!
				color = mix (color, environmentColor, mixRatioOnFresnel);
				
				gl_FragColor = vec4 (color, 1.0);
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
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{				
				vec3 tangent = normalize (WorldSpaceTangent);
				vec3 normal = normalize (WorldSpaceNormal);
				vec3 binormal = normalize (WorldSpaceBinormal);

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

				// Get view direction
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldSpacePosition));
				
				// Build local surface to world space matrix
				mat3 localSurface2World;
            	localSurface2World[0] = tangent;
            	localSurface2World[1] = binormal;
            	localSurface2World[2] = normal;
				
				// Sample normal map
				vec4 encodedNormal = texture2D (_NormalMap, gl_TexCoord[0].xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				vec3 normalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				normalDirection.z = sqrt (1.0 - dot (normalDirection, normalDirection));
				normalDirection = normalize (localSurface2World * normalDirection);
				
				// Calculate diffuse
				float diffuse = max (0.0, dot (normalDirection, lightDirection));

				// Calculate specular
				float specular = 0.0;
				if (diffuse > 0.0)
				{
					specular = pow (max (0.0, dot (reflect (-lightDirection, normalDirection), viewDirection)), _SpecularPower);
				}

				// Calculate base color
				vec3 color;
				color = vec3 (_AmbientColor);
				color += attenuation * vec3 (_LightColor0) * vec3 (_DiffuseColor) * diffuse;
				color += attenuation * vec3 (_LightColor0) * vec3 (_SpecularColor) * specular;
				
				// Look up environment map value in cube map
				vec3 reflectedDirection = reflect (-viewDirection, normalDirection);
				vec3 environmentColor = vec3 (textureCube (_EnvironmentMap, reflectedDirection));

				// "Fresnel" attenuates strength of reflection (According to Fresnel's law)
			    float fresnelMin = _FresnelScale * _MixRatio;
			    float fresnelCos = dot (viewDirection, normalDirection);
			    float mixRatioOnFresnel = fresnelMin + (_MixRatio - fresnelMin) * pow((1.0 - abs(fresnelCos)), _FresnelExponent);
			    
				// Mix!
				color = mix (color, environmentColor, mixRatioOnFresnel);
				
				gl_FragColor = vec4 (color, 1.0);
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}
