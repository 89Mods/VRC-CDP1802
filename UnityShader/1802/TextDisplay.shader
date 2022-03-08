Shader "Tholin/TextDisplay"
{
	Properties
	{
		_MainTex ("Emulator Texture", 2D) = "black" {}
		_Charset ("Charset Texture", 2D) = "black" {}
		[Toggle] _CursorEnabled ("Cursor Enabled", int) = 1
		_CursorInterval ("Cursor blink speed", float) = 1
		_Tint ("Text color tint", Color) = (1, 1, 1)
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
			#pragma target 3.0

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

			//64x50 chars
			sampler2D _MainTex;
			sampler2D _Charset;
			float4 _MainTex_ST;
			int _CursorEnabled;
			float _CursorInterval;
			fixed4 _Tint;

			#define byte_uv(x) (float2((float)((x) & 255) / 256.0f, (float)((x) >> 8) / 256.0f))

			uint read_memory_byte(int address) {
				float2 uv = byte_uv(address);
				float data = tex2D(_MainTex, uv).r;
				return (uint)(data * 255.0);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				if(i.uv.x < -0.02 || i.uv.y < -0.02 || i.uv.x > 1.02 || i.uv.y > 1.02) return fixed4(1, 0, 1, 1);
				uint charx = (uint)(i.uv.x * 64.0);
				uint chary = 49 - (uint)(i.uv.y * 50.0);
				if(chary > 50 || charx > 64) return fixed4(0, 0, 0, 1);
				uint bufferAddr = read_memory_byte(65535) | (read_memory_byte(65534) << 8);
				uint addr = bufferAddr + (chary * 64 + charx) * 2;
				uint ch = read_memory_byte(addr);
				if(ch == 0) ch = ' ';
				if(ch < ' ' || ch > 127) return fixed4(1, 0, 0, 1);
				uint icx = (uint)(i.uv.x * 64.0 * 6.0) % 6;
				uint icy = (uint)(i.uv.y * 50.0 * 9.0) % 9;
				if(icy == 8) return fixed4(0, 0, 0, 1);

				ch -= ' ';
				int charRow = ch / 13 + 1;
				int charCol = ch % 13;
				float2 uv = float2((float)charCol * 8.0 / 128.0, (float)charRow * 8.0 / 128.0);
				uv.y = 1.0 - uv.y;
				uv.x += (float)icx / 128.0;
				uv.y += (float)icy / 128.0;

				fixed4 color = tex2D(_Charset, uv);
				uint textColor = read_memory_byte(addr + 1);
				color.r *= (float)((textColor >> 4) & 3) / 3.0;
				color.g *= (float)((textColor >> 2) & 3) / 3.0;
				color.b *= (float)(textColor & 3) / 3.0;
				if(_CursorEnabled) {
					float cursorState = (_Time.y / _CursorInterval) % 1.0;
					if(cursorState < 0.5) {
						uint cursorRow = read_memory_byte(65532);
						if(chary != cursorRow) return color * _Tint;
						uint cursorCol = read_memory_byte(65533);
						if(charx != cursorCol) return color * _Tint;
						return (1.0 - color) * _Tint;
					}
				}

				return color * _Tint;
			}
			ENDCG
		}
	}
}
