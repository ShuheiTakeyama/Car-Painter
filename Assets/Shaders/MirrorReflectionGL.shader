Shader "ShaderMan/MirrorReflectionGL" 
{
	Properties 
	{
		_ColorMap ("Color Map ", 2D) = "white" {}
		_MirrorReflectionMap ("Mirror Reflection Map", 2D) = "white" {}
		_Reflectivity ("Reflectivity", Range (0.0, 1.0)) = 0.5
	}
	
	SubShader 
	{
		Pass
		{
			GLSLPROGRAM

			uniform sampler2D _ColorMap;
			uniform vec4 _ColorMap_ST;
			uniform sampler2D _MirrorReflectionMap;
			uniform mat4 _MirrorProjectionMatrix;
			uniform float _Reflectivity;
			
			#ifdef VERTEX
						
			void main ()
			{
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				gl_TexCoord[0] = gl_MultiTexCoord0;
				gl_TexCoord[1] = _MirrorProjectionMatrix * gl_Vertex;
			}
			
			#endif
			
			#ifdef FRAGMENT
			
			void main ()
			{
				vec4 color = texture2D (_ColorMap, gl_TexCoord[0].xy * _ColorMap_ST.xy + _ColorMap_ST.zw);
				vec4 reflectionColor = texture2DProj (_MirrorReflectionMap, gl_TexCoord[1]);
				gl_FragColor = mix (color, color * reflectionColor, _Reflectivity);
			}
			
			#endif
			
			ENDGLSL
		}
	} 
   // The definition of a fallback shader should be commented out 
   // during development:
   // Fallback "Diffuse"
}
