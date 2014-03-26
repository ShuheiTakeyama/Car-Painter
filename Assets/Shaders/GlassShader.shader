Shader "ShaderMan/GlassShader" 
{
	Properties 
	{
		_MainTex ("Refraction Map", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_Scale ("Scale", Vector) = (0.05, 0.05, 0.0, 0.0)
	}
	
	SubShader 
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			
			uniform sampler2D _MainTex;
			uniform sampler2D _RefractionMap;
			fixed _Scale;
			
			fixed4 frag(v2f_img i) : COLOR
			{
				fixed4 renderTex = tex2D(_MainTex, i.uv);
								
				fixed4 finalColor = renderTex;
				
				return finalColor;
			}
	
			ENDCG
		}
	} 
	FallBack off
}
