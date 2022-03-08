Shader "Tholin/CDP1802_v2_cached"
{
	Properties
	{
		_Program ("ROM Image", 2D) = "black" {}
		_Button ("Button texture", 2D) = "black" {}
		_IPF ("Instructions Per Frame", Int) = 64
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Lighting Off
		Blend One Zero
		LOD 100

		Pass
		{
			CGPROGRAM
			#include "UnityCustomRenderTexture.cginc"
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			#include "UnityCG.cginc"

			#define EMU_INIT 1
			#define EMU_RUNNING 2
			#define EMU_IDL 4
			#define EMU_INT_TRIG 8
			#define _IPF_MAX 64

			#define R0_H_ADDR 60000
			#define R0_L_ADDR 60001
			#define R1_H_ADDR 60002
			#define R1_L_ADDR 60003
			#define R2_H_ADDR 60004
			#define R2_L_ADDR 60005
			#define R3_H_ADDR 60006
			#define R3_L_ADDR 60007
			#define R4_H_ADDR 60008
			#define R4_L_ADDR 60009
			#define R5_H_ADDR 60010
			#define R5_L_ADDR 60011
			#define R6_H_ADDR 60012
			#define R6_L_ADDR 60013
			#define R7_H_ADDR 60014
			#define R7_L_ADDR 60015
			#define R8_H_ADDR 60016
			#define R8_L_ADDR 60017
			#define R9_H_ADDR 60018
			#define R9_L_ADDR 60019
			#define R10_H_ADDR 60020
			#define R10_L_ADDR 60021
			#define R11_H_ADDR 60022
			#define R11_L_ADDR 60023
			#define R12_H_ADDR 60024
			#define R12_L_ADDR 60025
			#define R13_H_ADDR 60026
			#define R13_L_ADDR 60027
			#define R14_H_ADDR 60028
			#define R14_L_ADDR 60029
			#define R15_H_ADDR 60030
			#define R15_L_ADDR 60031
			#define D_ADDR 60032
			#define DF_ADDR 60033
			#define P_ADDR 60034
			#define X_ADDR 60035
			#define T_ADDR 60036
			#define IE_ADDR 60037
			#define Q_ADDR 60038

			struct appdata
			{
				float2 uv : TEXCOORD0;
			};

			sampler2D _Program;
			sampler2D _Button;
			sampler2D _CPUInputGrab;
			int _IPF;

			#define byte_uv(x) (float2((float)((x) & 255) / 256.0f, (float)((x) >> 8) / 256.0f))
			#define read_reg(x) (((read_emulator_byte(R0_H_ADDR + (x) * 2) << 8) | (read_emulator_byte(R0_H_ADDR + (x) * 2 + 1))))

			uint read_emulator_byte(int address) {
				float2 uv = byte_uv(address);
				float data = tex2D(_SelfTexture2D, uv).g;
				return (uint)(data * 255.0);
			}

			uint read_memory_byte(int address) {
				float2 uv = byte_uv(address);
				float data = tex2D(_SelfTexture2D, uv).r;
				return (uint)(data * 255.0);
			}

			#define read_memory_cached(addr, res) { int bbb = 1; for(int i5 = i3 - 1; i5 >= 0; i5--) { if(cacheAddrs[i5] < 65536 && cacheAddrs[i5] == addr) { res = cacheVals[i5]; bbb = 0; break; } }; if(bbb) { res = read_memory_byte(addr); } }

			float4 frag (v2f_customrendertexture i) : COLOR
			{
				float4 checkCol = tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.672));
				if(abs(checkCol.r - 0.1) > 0.01 || abs(checkCol.g - 0.5) > 0.01 || abs(checkCol.b - 0.2) > 0.01) {

					//discard;
				}
				//Which bit are we on?
				uint idxx = (uint)(i.localTexcoord.x * 256.0);
				uint idxy = (uint)(i.localTexcoord.y * 256.0);
				uint idx = idxy * 256 + idxx;

				//Verify texture integrity
				uint integrityByte = read_emulator_byte(0);
				uint integrityByte2 = read_emulator_byte(65535);
				uint integrityByte3 = read_emulator_byte(255);
				uint integrityBad = 0;
				if(integrityByte != 0xAA || integrityByte2 != 0x55 || integrityByte3 != 0x3F) {
					integrityBad = 1;
				}

				//Check emulator status byte
				int status = integrityBad ? 0 : read_emulator_byte(301);
				if(status == 0 || tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).g > 0.5) { //Needs to be initialized
					float memoryInit = 0; //Initial value for this memory cell.
					if(idx < 32768) {
						memoryInit = tex2D(_Program, byte_uv(idx)).r;
					}
					if(idx == 0) return float4(memoryInit, (float)0xAA / 255.0, 0, 1); //Set integrityByte
					if(idx == 65535) return float4(memoryInit, (float)0x55 / 255.0, 0, 1); //Set integrityByte2
					if(idx == 255) return float4(memoryInit, (float)0x3F / 255.0, 0, 1); //Set integrityByte2
					if(idx == 301) { //Set status byte
						status = EMU_INIT; // Set emulator to initialized
						return float4(memoryInit, (float)status / 255.0, 0, 1);
					}
					if(idx >= 60000 && idx < 60000 + 32 + 7) { //CPU Registers, R1 - R15 + D + DF + P + X + T + IE + Q = 39 bytes
						return float4(memoryInit, 0, 0, 1);
					}
					if(idxy == 255) return float4(memoryInit, 1, 0, 1); //Debug. Should render a solid, visible line at the bottom of the RenderTexture.

					return float4(memoryInit, 0, 0, 1);
				}//else if(idxy == 255) return float4(0, 0, 0, 1);

				float4 col = tex2D(_SelfTexture2D, i.localTexcoord); //Return this if unchanged
				if(idxy == 254) return tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66));

				if((status & EMU_RUNNING) == 0) { //Emulator is paused
					if(idx == 301 && tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).r > 0.5) {
						status |= EMU_RUNNING;
						col.g = (float)status / 255.0;
					}
					return col;
				}

				if((status & EMU_INT_TRIG) != 0) { //Other shader has triggered a CPU interrupt
					//TODO

					if(idx == 301) { //Clear interrupt trigger and, if set, IDL status.
						status = status ^ EMU_INT_TRIG;
						status = status & (~EMU_IDL);
						col.g = (float)status / 255.0;
					}
					return col;
				}

				if((status & EMU_IDL) != 0) { //CPU is waiting for an interrupt
					return col;
				}

				uint regs[16];
				uint D,DF,X,P,T,IE,Q;
				//uint doWrite = 0;
				//uint wAddr = 0;
				//uint wVal = 0;

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
				D = read_emulator_byte(D_ADDR);
				DF = read_emulator_byte(DF_ADDR) & 1;
				X = read_emulator_byte(X_ADDR);
				P = read_emulator_byte(P_ADDR);
				T = read_emulator_byte(T_ADDR);
				IE = read_emulator_byte(IE_ADDR);
				Q = read_emulator_byte(Q_ADDR);
				uint cacheAddrs[_IPF_MAX];
				for(int i2 = 0; i2 < _IPF_MAX; i2++) cacheAddrs[i2] = 1000000;
				uint cacheVals[_IPF_MAX];

				[loop]
				for(int i3 = 0; i3 < _IPF; i3++) {
					//Fetch next instruction
					//uint opcode = read_memory_byte(regs[P]);
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
							//D = read_memory_byte(regs[N]);
							uint addr = regs[N];
							read_memory_cached(addr, D);
						}
					}else if(highnibble == 0x40) { //LDA
						//D = read_memory_byte(regs[N]);
						uint addr = regs[N];
						read_memory_cached(addr, D);
						regs[N]++;
						regs[N] &= 0xFFFF;
					}else if(opcode == 0xF0) { //LDX
						//D = read_memory_byte(regs[X]);
						uint addr = regs[X];
						read_memory_cached(addr, D);
					}else if(opcode == 0x72) { //LDXA
						//D = read_memory_byte(regs[X]);
						uint addr = regs[X];
						read_memory_cached(addr, D);
						regs[X]++;
						regs[X] &= 0xFFFF;
					}else if(opcode == 0xF8) { //LDI
						//D = read_memory_byte(regs[P]);
						uint addr = regs[P];
						read_memory_cached(addr, D);
						regs[P]++;
						regs[P] &= 0xFFFF;
					}else if(highnibble == 0x50) { //STR
						//doWrite = 1;
						//wAddr = regs[N];
						//wVal = D;
						//break;
						cacheAddrs[i3] = regs[N];
						cacheVals[i3] = D;
					}else if(opcode == 0x73) { //STXD
						//doWrite = 1;
						//wAddr = regs[X];
						//wVal = D;
						cacheAddrs[i3] = regs[X];
						cacheVals[i3] = D;
						regs[X]--;
						regs[X] &= 0xFFFF;
						//break;
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
						//D = D | read_memory_byte(regs[X]);
						uint nD;
						uint addr = regs[X];
						read_memory_cached(addr, nD);
						D = D | nD;
					}else if(opcode == 0xF9) { //ORI
						//D = D | read_memory_byte(regs[P]);
						uint nD;
						uint addr = regs[P];
						read_memory_cached(addr, nD);
						D = D | nD;
						regs[P]++;
						regs[P] &= 0xFFFF;
					}else if(opcode == 0xF3) { //XOR
						//D = D ^ read_memory_byte(regs[X]);
						uint nD;
						uint addr = regs[X];
						read_memory_cached(addr, nD);
						D = D ^ nD;
					}else if(opcode == 0xFB) { //XRI
						//D = D ^ read_memory_byte(regs[P]);
						uint nD;
						uint addr = regs[P];
						read_memory_cached(addr, nD);
						D = D ^ nD;
						regs[P]++;
						regs[P] &= 0xFFFF;
					}else if(opcode == 0xF2) { //AND
						//D = D & read_memory_byte(regs[X]);
						uint nD;
						uint addr = regs[X];
						read_memory_cached(addr, nD);
						D = D & nD;
					}else if(opcode == 0xFA) { //ANI
						//D = D & read_memory_byte(regs[P]);
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
						//D = D + read_memory_byte(regs[X]);
						uint nD;
						uint addr = regs[X];
						read_memory_cached(addr, nD);
						D = D + nD;
						DF = 0;
						if(D > 255) DF = 1;
						D &= 0xFF;
					}else if(opcode == 0xFC) { //ADI
						//D = D + read_memory_byte(regs[P]);
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
						//D = D + read_memory_byte(regs[X]) + DF;
						uint nD;
						uint addr = regs[X];
						read_memory_cached(addr, nD);
						D = D + nD + DF;
						DF = 0;
						if(D > 255) DF = 1;
						D &= 0xFF;
					}else if(opcode == 0x7C) { //ADCI
						//D = D + read_memory_byte(regs[P]) + DF;
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
						//int nD = read_memory_byte(regs[X]) - D;
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
						//int nD = read_memory_byte(regs[P]) - D;
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
						//int nD = read_memory_byte(regs[X]) - D - (!DF);
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
						//int nD = read_memory_byte(regs[P]) - D - (!DF);
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
						//int nD = D - read_memory_byte(regs[X]);
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
						//int nD = (int)D - (int)read_memory_byte(regs[P]);
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
						//int nD = D - read_memory_byte(regs[X]) - (!DF);
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
						//int nD = D - read_memory_byte(regs[P]) - (!DF);
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
						//doWrite = 1;
						//wAddr = regs[X];
						//wVal = T;
						//break;
						cacheAddrs[i3] = regs[X];
						cacheVals[i3] = T;
					}else if(opcode == 0x79) { //MARK
						//doWrite = 1;
						//wAddr = regs[2];
						//wVal = T = (X << 4) | P;
						cacheAddrs[i3] = regs[2];
						cacheVals[i3] = T = (X << 4) | P;
						regs[2]--;
						regs[2] &= 0xFFFF;
						X = P;
						//break;
					}else if(opcode == 0x70 || opcode == 0x71) { //RET,DIS
						//T = read_memory_byte(regs[X]);
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
							//uint dest = read_memory_byte(regs[P]);
							uint addr = regs[P];
							uint dest;
							read_memory_cached(addr, dest);
							regs[P] &= 0xFF00;
							regs[P] |= dest;
						}else if(br == 3) {
							//uint dest = read_memory_byte(regs[P]) << 8;
							//dest |= read_memory_byte((regs[P] + 1) & 0xFFFF);
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

				if(idx == 301) {
					if(tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).r <= 0.5) {
						status &= (~EMU_RUNNING);
					}else status |= EMU_RUNNING;
				}

				if(idx >= R0_H_ADDR && idx <= R15_L_ADDR) {
					uint idxr = idx - R0_H_ADDR;
					uint toWrite;
					if((idxr & 1) == 0) toWrite = regs[idxr / 2] >> 8;
					else toWrite = regs[idxr / 2] & 0xFF;

					col.g = (float)toWrite / 255.0;
				}else if(idx == D_ADDR) {
					col.g = (float)D / 255.0;
				}else if(idx == DF_ADDR) {
					col.g = (float)DF / 255.0;
				}else if(idx == X_ADDR) {
					col.g = (float)X / 255.0;
				}else if(idx == P_ADDR) {
					col.g = (float)P / 255.0;
				}else if(idx == T_ADDR) {
					col.g = (float)T / 255.0;
				}else if(idx == IE_ADDR) {
					col.g = (float)IE / 255.0;
				}else if(idx == Q_ADDR) {
					col.g = (float)Q / 255.0;
				}else if(idx == 301) {
					col.g = (float)status / 255.0;
				}

				///if(doWrite) {
				//	if(idx == wAddr) {
				//		col.r = (float)wVal / 255.0;
				//	}
				//}

				for(int i4 = 0; i4 < _IPF_MAX; i4++) {
					if(cacheAddrs[i4] < 65536 && cacheAddrs[i4] == idx) {
						col.r = (float)cacheVals[i4] / 255.0;
					}
				}

				if(idx == 65530) {
					float cond1 = length(tex2D(_Button, float2(0.5, 0.5)));
					float cond2 = length(tex2D(_Button, float2(1.0, 0.0)));
					float cond3 = length(tex2D(_Button, float2(0.0, 1.0)));
					float cond4 = length(tex2D(_Button, float2(0.0, 0.0)));
					float cond5 = length(tex2D(_Button, float2(1.0, 1.0)));
					if(cond1 > 0.02 || cond2 > 0.02 || cond3 > 0.02 || cond4 > 0.02 || cond5 > 0.02) {
						col.r = 1.0;
					}else col.r = 0.0;
				}

				if(idx == 65529) {
					col.r = tex2D(_CPUInputGrab, float2(0.314453125, 1.0 - 0.66)).b;
				}

				if(idxy >= 238 && idxy < 254 && idxx >= 64 && idxx < 96) {
					uint rshift = 15 - (idxy - 238);
					col.g = 0.25;

					uint debugval = regs[(idxx - 64) / 2];
					if(((debugval >> rshift) & 1) != 0) {
						col.g = 1.0;
					}
				}

				if(idxy >= 238 && idxy < 254 && idxx >= 100 && idxx < 114) {
					uint reg = (idxx - 100) / 2;
					uint val = reg == 0 ? D : (reg == 1 ? DF : (reg == 2 ? X : (reg == 3 ? P : (reg == 4 ? T : (reg == 5 ? IE : Q)))));

					col.g = 0.25;
					if(reg == 1 || reg == 5 || reg == 6) {
						if(val != 0) col.g = 1.0;
					}else if(reg == 0 || reg == 4) {
						uint rshift = 7 - (idxy - 238) / 2;
						if(((val >> rshift) & 1) != 0) {
							col.g = 1.0;
						}
					}else {
						uint rshift = 3 - (idxy - 238) / 4;
						if(((val >> rshift) & 1) != 0) {
							col.g = 1.0;
						}
					}
				}

				return col;
			}
			ENDCG
		}
	}
}
