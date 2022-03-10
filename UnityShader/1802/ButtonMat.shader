Shader "Tholin/TouchButtonMat"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_OffCol ("Off Color", Color) = (0,0,0,1)
		_OnCol ("On Color", Color) = (1,1,1,1)
		_MemoryLoc ("Value memory address", Int) = 65531
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			Texture2D<uint4> _MainTex;
			half4 _OffCol;
			half4 _OnCol;
			int _MemoryLoc;

			uint read_memory_byte(int address) {
				return _MainTex[uint2(address & 0xFF, address >> 8)].x & 0xFF;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				half4 col = _OffCol;
				if(read_memory_byte(_MemoryLoc)) col = _OnCol;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
