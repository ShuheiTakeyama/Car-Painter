Shader "ShaderMan/GlassShaderGL" 
{
	Properties 
	{
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_RefractionMap ("Refraction Map", 2D) = "white" {}
		_Scale ("Scale", Vector) = (0.05, 0.05, 0.0, 0.0)
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

			uniform sampler2D _NormalMap;
			uniform vec4 _NormalMap_ST;
			uniform sampler2D _RefractionMap;
			uniform vec4 _Scale;
			
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
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				gl_TexCoord[0] = gl_MultiTexCoord0;
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{
				// Sample normal maps
				vec4 encodedNormal;
				
				encodedNormal = texture2D (_NormalMap, gl_TexCoord[0].xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
				vec3 normalDirection = vec3 (2.0 * encodedNormal.ag - vec2 (1.0), 0.0);
				normalDirection.z = sqrt (1.0 - dot (normalDirection, normalDirection));
				normalDirection = normalize (normalDirection);
				
				// Displace texture coordinates
				vec2 newTextureCoordinates = gl_FragCoord.xy / _ScreenParams.xy + normalDirection.xy * _Scale.xy;
				
				// Sample refraction map
				vec4 refractionColor = texture2D (_RefractionMap, newTextureCoordinates);
				
				gl_FragColor = refractionColor;
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}

