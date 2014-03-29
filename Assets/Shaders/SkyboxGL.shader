Shader "ShaderMan/SkyboxGL" 
{
	Properties 
	{
		_EnvironmentMap ("Environment Map", CUBE) = "" {}
	}
	
	SubShader 
	{
		Tags
		{
			"Queue" = "Background"
		}
			
		Pass
		{			
			ZWrite Off
			Cull Front
			
			GLSLPROGRAM
			
			uniform samplerCube _EnvironmentMap;
		
			uniform mat4 _Object2World;
			uniform vec3 _WorldSpaceCameraPos;
						
			varying vec3 WorldSpaceViewDirection;
						
			#ifdef VERTEX
						
			void main ()
			{
				WorldSpaceViewDirection = vec3 (_Object2World * gl_Vertex - vec4 (_WorldSpaceCameraPos, 1.0));
			
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{				
				gl_FragColor = textureCube (_EnvironmentMap, WorldSpaceViewDirection);
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}

