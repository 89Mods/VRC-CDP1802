Shader "Tholin/CDP1802Emissives"
{
	Properties
	{
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_EmissionMask ("Emission Mask", 2D) = "white" {}
		_CRT ("CDP1802 CRT", 2D) = "black" {}
		_MemoryLoc ("Value memory address", Int) = 65531
		_Color ("Emissions Color", Color) = (1, 1, 1, 1)
		_Normals ("Normal map", 2D) = "black" {}
		_NormalStrength ("Normal Strength", Range(0, 1)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows

		#pragma target 3.0

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_EmissionMask;
			float2 uv_Normals;
		};

		sampler2D _MainTex;
		sampler2D _EmissionMask;
		sampler2D _CRT;
		sampler2D _Normals;
		fixed4 _Color;
		int _MemoryLoc;
		half _NormalStrength;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		#define byte_uv(x) (float2((float)((x) & 255) / 256.0f, (float)((x) >> 8) / 256.0f))

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			fixed4 e = tex2D (_EmissionMask, IN.uv_EmissionMask);
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			float2 buv = byte_uv(_MemoryLoc);
			float v = tex2D(_CRT, buv).r;
			fixed4 ec = _Color * v;
			o.Albedo = c;
			o.Emission = e * ec;
			o.Metallic = 0;
			o.Smoothness = 0;
			o.Alpha = 1;
			o.Normal = UnpackScaleNormal(tex2D(_Normals, IN.uv_Normals), _NormalStrength);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
