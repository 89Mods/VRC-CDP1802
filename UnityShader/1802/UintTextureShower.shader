Shader "Tholin/Unlit/UINTTextureShower"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#include "rvc-crt.cginc"
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			struct appdata
			{
				float2 uv : TEXCOORD0;
			};

			Texture2D<uint4> _MainTex;

			float4 frag (v2f_customrendertexture i) : SV_Target
			{
				uint4 s = _MainTex[uint2((uint)(i.localTexcoord.x * 256.0), (uint)(i.localTexcoord.y * 256.0))];
				float4 col = float4(0, 0, 0, 1);
				col.r = (float)(s.x & 0xFF) / 255.0;
				col.g = (float)(s.y & 0xFF) / 255.0;
				col.b = (float)(s.z & 0xFF) / 255.0;
				return col;
			}
			ENDCG
		}
	}
}
