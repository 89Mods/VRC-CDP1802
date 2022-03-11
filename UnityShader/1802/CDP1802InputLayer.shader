Shader "Tholin/CDP1802InputLayer"
{
	Properties
	{
		[Toggle] _Pause ("Pause Emulation", Int) = 0
		[Toggle] _Reset ("Reset Emulation", Int) = 0
		_KeypadInput ("Keypad Input", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Background-6" }
		Cull Off
		ZWrite Off
		ZTest Always
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 vertOrig : COLOR0;
			};

			int _Pause;
			int _Reset;
			float _KeypadInput;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertOrig = v.vertex;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = fixed4(!_Pause, _Reset, _KeypadInput, 1);
				return col;
			}
			ENDCG
		}
	}
}
