Shader "ShaderMan/PhongGL" 
{
	Properties 
	{
		_DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
		_SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
		_SpecularPower ("Specular Power", Range (0.0, 64.0)) = 16.0
		_AmbientColor ("Ambient Color", Color) = (0, 0, 0, 0)
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
			
			uniform mat4 _Object2World;
			uniform mat4 _World2Object;
			uniform vec3 _WorldSpaceCameraPos;
			uniform vec4 _WorldSpaceLightPos0;
			uniform vec4 _LightColor0;
			
			varying vec4 WorldPosition;
			varying vec3 WorldNormal;
			
			#ifdef VERTEX
			
			void main ()
			{
				WorldPosition = _Object2World * gl_Vertex;
				WorldNormal = normalize (vec3 (vec4 (gl_Normal, 0.0) * _World2Object));
				
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{
				vec3 normalDirection = normalize (WorldNormal);
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldPosition));
				
				vec3 lightDirection;
				float attenuation;
				
				if (0.0 == _WorldSpaceLightPos0.w)
				{
					attenuation = 1.0;
					lightDirection = normalize (vec3 (_WorldSpaceLightPos0));
				}
				else
				{
					lightDirection = vec3 (_WorldSpaceLightPos0 - WorldPosition);
					float distance = length (lightDirection);
					attenuation = 1.0 / distance;
					lightDirection = normalize (lightDirection);
				}
				
				float diffuse = max (0.0, dot (normalDirection, lightDirection));
				float specular = 0.0;
				if (diffuse > 0.0)
				{
					specular = pow (max (0.0, dot (reflect (-lightDirection, normalDirection), viewDirection)), _SpecularPower);
				}

				vec3 color;
				color = vec3 (_AmbientColor);
				color += attenuation * vec3 (_LightColor0) * vec3 (_DiffuseColor) * diffuse;
				color += attenuation * vec3 (_LightColor0) * vec3 (_SpecularColor) * specular;
				
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

			uniform mat4 _Object2World;
			uniform mat4 _World2Object;
			uniform vec3 _WorldSpaceCameraPos;
			uniform vec4 _WorldSpaceLightPos0;
			uniform vec4 _LightColor0;
			
			varying vec4 WorldPosition;
			varying vec3 WorldNormal;
			
			#ifdef VERTEX
			
			void main ()
			{
				WorldPosition = _Object2World * gl_Vertex;
				WorldNormal = normalize (vec3 (vec4 (gl_Normal, 0.0) * _World2Object));
				
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{
				vec3 normalDirection = normalize (WorldNormal);
				vec3 viewDirection = normalize (_WorldSpaceCameraPos - vec3 (WorldPosition));
				
				vec3 lightDirection;
				float attenuation;
				
				if (0.0 == _WorldSpaceLightPos0.w)
				{
					attenuation = 1.0;
					lightDirection = normalize (vec3 (_WorldSpaceLightPos0));
				}
				else
				{
					lightDirection = vec3 (_WorldSpaceLightPos0 - WorldPosition);
					float distance = length (lightDirection);
					attenuation = 1.0 / distance;
					lightDirection = normalize (lightDirection);
				}
				
				float diffuse = max (0.0, dot (normalDirection, lightDirection));
				float specular = 0.0;
				if (diffuse > 0.0)
				{
					specular = pow (max (0.0, dot (reflect (-lightDirection, normalDirection), viewDirection)), _SpecularPower);
				}

				vec3 color;
				color = vec3 (_AmbientColor);
				color += attenuation * vec3 (_LightColor0) * vec3 (_DiffuseColor) * diffuse;
				color += attenuation * vec3 (_LightColor0) * vec3 (_SpecularColor) * specular;
				
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
