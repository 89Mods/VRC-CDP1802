Shader "Tholin/CDP1802_v2_cached"
{
	Properties
	{
		_Program ("ROM Image", 2D) = "black" {}
		_Button ("Button texture", 2D) = "black" {}
		_IPF ("Target Instructions Per Second", Int) = 64
		[Toggle] _IgnoreInput ("Ignore input layer", Int) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Lighting Off
		Blend One Zero
		ZTest Always
		LOD 100

		Pass
		{
			CGPROGRAM
			#include "rvc-crt.cginc"
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			#define EMU_INIT 1
			#define EMU_RUNNING 2
			#define EMU_IDL 4
			#define EMU_INT_TRIG 8
			#define EMU_STAGE 16
			#define _IPF_MAX 196
			#define _CACHE_SIZE (_IPF_MAX / 4)

			#define STATUS_ADDR 59904
			#define R0_ADDR 59905
			#define R1_ADDR 59906
			#define R2_ADDR 59907
			#define R3_ADDR 59908
			#define R4_ADDR 59909
			#define R5_ADDR 59910
			#define R6_ADDR 59911
			#define R7_ADDR 59912
			#define R8_ADDR 59913
			#define R9_ADDR 59914
			#define R10_ADDR 59915
			#define R11_ADDR 59916
			#define R12_ADDR 59917
			#define R13_ADDR 59918
			#define R14_ADDR 59919
			#define R15_ADDR 59920
			#define D_DF_ADDR 59921
			#define P_ADDR 59922
			#define X_ADDR 59923
			#define T_ADDR 59924
			#define IE_ADDR 59925
			#define Q_ADDR 59926
			#define CACHE_SIZE_ADDR 59927
			#define CACHE_START 59928

			struct appdata
			{
				float2 uv : TEXCOORD0;
			};

			sampler2D _Program;
			sampler2D _Button;
			sampler2D _CPUInputGrab;
			int _IPF;
			int _IgnoreInput;

			#define byte_uv(x) (float2((float)((x) & 255) / 256.0f, (float)((x) >> 8) / 256.0f))
			#define read_reg(x) (read_emulator_word(R0_ADDR + (x)) & 0xFFFF)
			#define read_emulator_byte(address) (_SelfTexture2D[uint2((address) & 0xFF, (address) >> 8)].y & 0xFF)
			#define read_emulator_word(address) (_SelfTexture2D[uint2((address) & 0xFF, (address) >> 8)].y)
			#define read_memory_byte(address) (_SelfTexture2D[uint2((address) & 0xFF, (address) >> 8)].x & 0xFF)

			#define read_memory_cached(addr, res) { int bbb = 1; for(int i5 = cacheSize - 1; i5 >= 0; i5--) { if(cacheAddrs[i5] == addr) { res = cacheVals[i5]; bbb = 0; break; } }; if(bbb) { res = read_memory_byte(addr); } }

			uint4 frag (v2f_customrendertexture i) : COLOR
			{
				//Verify texture integrity
				uint integrityByte = read_emulator_byte(0);
				uint integrityByte2 = read_emulator_byte(65535);
				uint integrityByte3 = read_emulator_byte(255);
				uint integrityBad = 0;
				if(integrityByte != 0xAA || integrityByte2 != 0x55 || integrityByte3 != 0x3F) {
					integrityBad = 1;
				}

				//Check emulator status byte
				int status = integrityBad ? 0 : read_emulator_byte(STATUS_ADDR);

				//Which bit are we on?
				uint idxx = (uint)(i.globalTexcoord.x * 256.0);
				uint idxy = (uint)(i.globalTexcoord.y * 256.0);
				uint idx = idxy * 256 + idxx;

				if(status == 0 || (!_IgnoreInput && tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).g < 0.4)) { //Needs to be initialized
					uint memoryInit = 0; //Initial value for this memory cell.
					if(idx < 32768) {
						memoryInit = (int)(tex2D(_Program, byte_uv(idx)).r * 255.0);
					}
					if(idx == 0) return uint4(memoryInit, 0xAA, 0, 0xFFFFFFFF); //Set integrityByte
					if(idx == 65535) return uint4(memoryInit, 0x55, 0, 0xFFFFFFFF); //Set integrityByte2
					if(idx == 255) return uint4(memoryInit, 0x3F, 0, 0xFFFFFFFF); //Set integrityByte2
					if(idx == STATUS_ADDR) { //Set status byte
						status = EMU_INIT; // Set emulator to initialized
						return uint4(memoryInit, status, 0, 0xFFFFFFFF);
					}
					if(idx >= 60000 && idx < 60000 + 32 + 7) { //CPU Registers, R1 - R15 + D + DF + P + X + T + IE + Q = 39 bytes
						return uint4(memoryInit, 0, 0, 0xFFFFFFFF);
					}
					if(idxy == 255) return uint4(memoryInit, 0xFFFFFFFF, 0, 0xFFFFFFFF); //Debug. Should render a solid, visible line at the bottom of the RenderTexture.

					return uint4(memoryInit, 0, 0, 0xFFFFFFFF);
				}//else if(idxy == 255) return uint4(0, 0, 0, 0xFFFFFFFF);

				uint4 col = _SelfTexture2D[uint2(idxx, idxy)]; //Return this if unchanged
				/*if(idxy == 254) {
					float4 a = tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66));
					return uint4((uint)(a.r * 255), (uint)(a.g * 255), (uint)(a.b * 255), 0xFFFFFFFF);
				}*/

				if((status & EMU_RUNNING) == 0) { //Emulator is paused
					if(idx == STATUS_ADDR && (_IgnoreInput || tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).r > 0.5)) {
						status |= EMU_RUNNING;
						col.y = status;
					}
					return col;
				}

				if((status & EMU_INT_TRIG) != 0) { //Other shader has triggered a CPU interrupt
					//TODO

					if(idx == STATUS_ADDR) { //Clear interrupt trigger and, if set, IDL status.
						status = status ^ EMU_INT_TRIG;
						status = status & (~EMU_IDL);
						col.y = status;
					}
					return col;
				}

				if((status & EMU_IDL) != 0) { //CPU is waiting for an interrupt
					return col;
				}

				if(!i.primitiveID) { //Commit memory changes
					status ^= EMU_STAGE;

					uint cacheSize = read_emulator_byte(CACHE_SIZE_ADDR);
					for(int i4 = cacheSize - 1; i4 >= 0; i4--) {
						uint val = read_emulator_word(CACHE_START + i4);
						uint addr = val & 0xFFFF;
						if(addr == 0) break;
						if(addr == idx) {
							col.x = val >> 16;
							break;
						}
					}

					if(idx == STATUS_ADDR) col.y = status;

					if(idx == 65530) {
						float cond1 = length(tex2D(_Button, float2(0.5, 0.5)));
						float cond2 = length(tex2D(_Button, float2(1.0, 0.0)));
						float cond3 = length(tex2D(_Button, float2(0.0, 1.0)));
						float cond4 = length(tex2D(_Button, float2(0.0, 0.0)));
						float cond5 = length(tex2D(_Button, float2(1.0, 1.0)));
						if(cond1 > 0.02 || cond2 > 0.02 || cond3 > 0.02 || cond4 > 0.02 || cond5 > 0.02) {
							col.x = 10;
						}else col.x = 0;
					}

					if(idx == 65529 && !_IgnoreInput) {
						float3 inp = tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66));
						if(inp.r > 0.5 && inp.g > 0.5 && inp.b > 0.5) {
							uint b1 = inp.r >= 0.64 ? 1 : 0;
							uint b2 = inp.g >= 0.64 ? 1 : 0;
							uint b3 = inp.b >= 0.64 ? 1 : 0;
							col.x = (b3 << 2) | (b2 << 1) | b1;
						}
					}

					if(idxy >= 238 && idxy < 254 && idxx >= 64 && idxx < 96) {
						uint rshift = 15 - (idxy - 238);
						col.y = 0x3F;

						uint debugval = read_reg((idxx - 64) / 2);
						if(((debugval >> rshift) & 1) != 0) {
							col.y = 0xFF;
						}
					}

					if(idxy >= 238 && idxy < 254 && idxx >= 100 && idxx < 114) {
						uint reg = (idxx - 100) / 2;
						uint val;
						if(reg < 2) {
							uint a = read_emulator_word(D_DF_ADDR);
							if(reg == 0) val = a & 0xFF;
							else val = (a >> 8) & 1;
						}else val = read_emulator_byte(D_DF_ADDR + reg - 1);

						col.y = 0x3F;
						if(reg == 1 || reg == 5 || reg == 6) {
							if(val != 0) col.y = 0xFF;
						}else if(reg == 0 || reg == 4) {
							uint rshift = 7 - (idxy - 238) / 2;
							if(((val >> rshift) & 1) != 0) {
								col.y = 0xFF;
							}
						}else {
							uint rshift = 3 - (idxy - 238) / 4;
							if(((val >> rshift) & 1) != 0) {
								col.y = 0xFF;
							}
						}
					}

				}else { //Compute next machine state
					status ^= EMU_STAGE;

					if(idx >= CACHE_START + _CACHE_SIZE && idx <= CACHE_START + _CACHE_SIZE + 3) {
						col.y = 0xFF;
						return col;
					}
					if(idx < STATUS_ADDR || idx > CACHE_START + _CACHE_SIZE) return col;

					uint regs[16];
					uint D,DF,X,P,T,IE,Q;

					regs[0] = read_reg(0);
					regs[1] = read_reg(1);
					regs[2] = read_reg(2);
					regs[3] = read_reg(3);
					regs[4] = read_reg(4);
					regs[5] = read_reg(5);
					regs[6] = read_reg(6);
					regs[7] = read_reg(7);
					regs[8] = read_reg(8);
					regs[9] = read_reg(9);
					regs[10] = read_reg(10);
					regs[11] = read_reg(11);
					regs[12] = read_reg(12);
					regs[13] = read_reg(13);
					regs[14] = read_reg(14);
					regs[15] = read_reg(15);
					D = read_emulator_word(D_DF_ADDR);
					DF = (D >> 8) & 1;
					D &= 0xFF;
					X = read_emulator_byte(X_ADDR);
					P = read_emulator_byte(P_ADDR);
					T = read_emulator_byte(T_ADDR);
					IE = read_emulator_byte(IE_ADDR);
					Q = read_emulator_byte(Q_ADDR);
					uint cacheSize = 0;
					uint cacheAddrs[_CACHE_SIZE];
					uint cacheVals[_CACHE_SIZE];

					uint loops = (uint)ceil((float)_IPF * unity_DeltaTime.x);
					if(loops > _IPF_MAX) loops = _IPF_MAX;

					[loop]
					for(int i3 = 0; i3 < loops; i3++) {
						if(cacheSize == _CACHE_SIZE) break;
						//Fetch next instruction
						uint addr = regs[P];
						uint opcode;
						read_memory_cached(addr, opcode);
						regs[P]++;
						regs[P] &= 0xFFFF;

						//Decode and execute
						uint highnibble = opcode & 0xF0;
						uint N = opcode & 0x0F;
						if(highnibble == 0x00) {
							if(opcode == 0x00) { //IDL
								status = status | EMU_IDL;
								break;
							}else { //LDN
								uint addr = regs[N];
								read_memory_cached(addr, D);
							}
						}else if(highnibble == 0x40) { //LDA
							uint addr = regs[N];
							read_memory_cached(addr, D);
							regs[N]++;
							regs[N] &= 0xFFFF;
						}else if(opcode == 0xF0) { //LDX
							uint addr = regs[X];
							read_memory_cached(addr, D);
						}else if(opcode == 0x72) { //LDXA
							uint addr = regs[X];
							read_memory_cached(addr, D);
							regs[X]++;
							regs[X] &= 0xFFFF;
						}else if(opcode == 0xF8) { //LDI
							uint addr = regs[P];
							read_memory_cached(addr, D);
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(highnibble == 0x50) { //STR
							cacheAddrs[cacheSize] = regs[N];
							cacheVals[cacheSize] = D;
							cacheSize++;
						}else if(opcode == 0x73) { //STXD
							cacheAddrs[cacheSize] = regs[X];
							cacheVals[cacheSize] = D;
							cacheSize++;
							regs[X]--;
							regs[X] &= 0xFFFF;
						}else if(highnibble == 0x10) { //INC
							regs[N]++;
							regs[N] &= 0xFFFF;
						}else if(highnibble == 0x20) { //DEC
							regs[N]--;
							regs[N] &= 0xFFFF;
						}else if(opcode == 0x60) { //IRX
							regs[X]++;
							regs[X] &= 0xFFFF;
						}else if(highnibble == 0x80) { //GLO
							D = regs[N] & 0xFF;
						}else if(highnibble == 0xA0) { //PLO
							regs[N] &= 0xFF00;
							regs[N] |= D;
						}else if(highnibble == 0x90) { //GHI
							D = regs[N] >> 8;
						}else if(highnibble == 0xB0) { //PHI
							regs[N] &= 0x00FF;
							regs[N] |= D << 8;
						}else if(opcode == 0xF1) { //OR
							uint nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							D = D | nD;
						}else if(opcode == 0xF9) { //ORI
							uint nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							D = D | nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0xF3) { //XOR
							uint nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							D = D ^ nD;
						}else if(opcode == 0xFB) { //XRI
							uint nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							D = D ^ nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0xF2) { //AND
							uint nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							D = D & nD;
						}else if(opcode == 0xFA) { //ANI
							uint nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							D = D & nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0xF6) { //SHR
							DF = D & 1;
							D = D >> 1;
						}else if(opcode == 0x76) { //SHRC,RSHR
							uint z = D & 1;
							D = D >> 1;
							D = D | (DF << 7);
							DF = z;
						}else if(opcode == 0xFE) { //SHL
							DF = (D & 128) >> 7;
							D = D << 1;
							D &= 0xFF;
						}else if(opcode == 0x7E) { //SHLC,RSHL
							int z = (D & 128) >> 7;
							D = D << 1;
							D &= 0xFF;
							D |= DF;
							DF = z;
						}else if(opcode == 0xF4) { //ADD
							uint nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							D = D + nD;
							DF = 0;
							if(D > 255) DF = 1;
							D &= 0xFF;
						}else if(opcode == 0xFC) { //ADI
							uint nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							D = D + nD;
							DF = 0;
							if(D > 255) DF = 1;
							D &= 0xFF;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0x74) { //ADC
							uint nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							D = D + nD + DF;
							DF = 0;
							if(D > 255) DF = 1;
							D &= 0xFF;
						}else if(opcode == 0x7C) { //ADCI
							uint nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							D = D + nD + DF;
							DF = 0;
							if(D > 255) DF = 1;
							D &= 0xFF;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0xF5) { //SD
							int nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							nD = nD - D;
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
						}else if(opcode == 0xFD) { //SDI
							int nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							nD = nD - D;
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0x75) { //SDB
							int nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							nD = nD - D - (!DF);
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
						}else if(opcode == 0x7D) { //SDBI
							int nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							nD = nD - D - (!DF);
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0xF7) { //SM
							int nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							nD = D - nD;
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
						}else if(opcode == 0xFF) { //SMI
							int nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							nD = D - nD;
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0x77) { //SMB
							int nD;
							uint addr = regs[X];
							read_memory_cached(addr, nD);
							nD = D - nD - (!DF);
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
						}else if(opcode == 0x7F) { //SMBI
							int nD;
							uint addr = regs[P];
							read_memory_cached(addr, nD);
							nD = D - nD - (!DF);
							DF = 1;
							if(nD < 0) {
								DF = 0;
								nD = 256 + nD;
							}
							D = nD;
							regs[P]++;
							regs[P] &= 0xFFFF;
						}else if(opcode == 0xC4) { //NOP
							//Nothing, lol
						}else if(highnibble == 0xD0) { //SEP
							P = N;
						}else if(highnibble == 0xE0) { //SEX
							X = N;
						}else if(opcode == 0x7B) { //SEQ
							Q = 222;
						}else if(opcode == 0x7A) { //REQ
							Q = 0;
						}else if(opcode == 0x78) { //SAV
							cacheAddrs[cacheSize] = regs[X];
							cacheVals[cacheSize] = T;
							cacheSize++;
						}else if(opcode == 0x79) { //MARK
							cacheAddrs[cacheSize] = regs[2];
							cacheVals[cacheSize] = T = (X << 4) | P;
							cacheSize++;
							regs[2]--;
							regs[2] &= 0xFFFF;
							X = P;
						}else if(opcode == 0x70 || opcode == 0x71) { //RET,DIS
							uint addr = regs[X];
							read_memory_cached(addr, T);
							regs[X]++;
							regs[X] &= 0xFFFF;
							X = T >> 4;
							P = T & 15;
							IE = opcode == 0x70 ? 255 : 0;
						}else if(opcode >= 0x61 && opcode <= 0x67) { //OUT instructions - currently do nothing but increment the stack pointer
							regs[X]++;
							regs[X] &= 0xFFFF;
						}else if(opcode == 0x68) { //CDP1805/1806 extended instructions. TODO
							uint addr = regs[P];
							uint ext_opcode;
							read_memory_cached(addr, ext_opcode);
							regs[P]++;
							regs[P] &= 0xFFFF;
							if(ext_opcode == 0xE0) break;
						}else {
							//These next instructions are all control flow instructions
							int br = 4; //Result of branch operation. 0 = skip, 1 = long-skip, 2 = short branch, 3 = long branch, 4 = no change (continue execution at next byte)
							//Short-branches
							if(opcode == 0x30) br = 2; //BR
							else if(opcode == 0x32) { if(D == 0) { br = 2; } else { br = 0; } } //BZ
							else if(opcode == 0x3A) { if(D != 0) { br = 2; } else { br = 0; } } //BNZ
							else if(opcode == 0x33) { if(DF != 0) { br = 2; } else { br = 0; } } //BDF
							else if(opcode == 0x3B) { if(DF == 0) { br = 2; } else { br = 0; } } //BNF
							else if(opcode == 0x31) { if(Q != 0) { br = 2; } else { br = 0; } } //BQ
							else if(opcode == 0x39) { if(Q == 0) { br = 2; } else { br = 0; } } //BNQ
							//Short-skip
							else if(opcode == 0x38) br = 0; //NBR,SKP
							//Long-branches
							else if(opcode == 0xC0) br = 3; //LBR
							else if(opcode == 0xC2) { if(D == 0) { br = 3; } else { br = 1; } } //LBZ
							else if(opcode == 0xCA) { if(D != 0) { br = 3; } else { br = 1; } } //LBNZ
							else if(opcode == 0xC3) { if(DF != 0) { br = 3; } else { br = 1; } } //LBDF
							else if(opcode == 0xCB) { if(DF == 0) { br = 3; } else { br = 1; } } //LBNF
							else if(opcode == 0xC1) { if(Q != 0) { br = 3; } else { br = 1; } } //LBQ
							else if(opcode == 0xC9) { if(Q == 0) { br = 3; } else { br = 1; } } //LBNQ
							//Long-skips
							else if(opcode == 0xC8) br = 1; //NLBR,LSKP
							else if(opcode == 0xCE && D == 0) br = 1; //LSZ
							else if(opcode == 0xC6 && D != 0) br = 1; //LSNZ
							else if(opcode == 0xCF && DF != 0) br = 1; //LSDF
							else if(opcode == 0xC7 && DF == 0) br = 1; //LSNF
							else if(opcode == 0xCD && Q != 0) br = 1; //LSQ
							else if(opcode == 0xC5 && Q == 0) br = 1; //LSNQ
							else if(opcode == 0xCC && IE != 0) br = 1; //LSIE
							else br = 4;

							if(br == 0) regs[P]++;
							else if(br == 1) regs[P] += 2;
							else if(br == 2) {
								uint addr = regs[P];
								uint dest;
								read_memory_cached(addr, dest);
								regs[P] &= 0xFF00;
								regs[P] |= dest;
							}else if(br == 3) {
								uint addr = regs[P];
								uint dest,tmp;
								read_memory_cached(addr, dest);
								dest <<= 8;
								addr = regs[P] + 1;
								read_memory_cached(addr, tmp);
								dest |= tmp;
								regs[P] = dest;
							}

							regs[P] &= 0xFFFF;
						}
					}

					if(idx == STATUS_ADDR) {
						if(!_IgnoreInput && tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).r <= 0.5) {
							status &= (~EMU_RUNNING);
						}else status |= EMU_RUNNING;
					}

					if(idx >= R0_ADDR && idx <= R15_ADDR) {
						uint idxr = idx - R0_ADDR;
						col.y = regs[idxr];
					}else if(idx == D_DF_ADDR) {
						col.y = D | (DF << 8);
					}else if(idx == X_ADDR) {
						col.y = X;
					}else if(idx == P_ADDR) {
						col.y = P;
					}else if(idx == T_ADDR) {
						col.y = T;
					}else if(idx == IE_ADDR) {
						col.y = IE;
					}else if(idx == Q_ADDR) {
						col.y = Q;
					}else if(idx == STATUS_ADDR) {
						col.y = status;
					}else if(idx == CACHE_SIZE_ADDR) {
						col.y = cacheSize;
					}

					if(idx >= CACHE_START && idx <= CACHE_START + _CACHE_SIZE) col.y = col.z = 0;
					for(uint i4 = 0; i4 < cacheSize; i4++) {
						if(idx == CACHE_START + i4) {
							col.y = cacheAddrs[i4] | (cacheVals[i4] << 16);
							break;
						}
					}
				}

				return col;
			}
			ENDCG
		}
	}
}
