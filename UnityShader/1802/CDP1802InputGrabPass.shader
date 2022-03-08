﻿Shader "Tholin/CDP1802InputGrabPass"
{
	Properties
	{

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Background-4" "PreviewType"="Quad" }
		Cull Off
		ZWrite Off
		ZTest Always
		LOD 100

		GrabPass
		{
			"_CPUInputGrab"
		}

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
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			uniform sampler2D _CPUInputGrab;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_CPUInputGrab, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
