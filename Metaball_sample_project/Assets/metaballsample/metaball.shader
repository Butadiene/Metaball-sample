// The MIT License
// Copyright © 2019 Butadiene
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Use directional light
Shader "Butadiene/metaball"
{
	Properties
	{
		_ypos("floor high",float)=-0.25

		}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Front
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			uniform float _ypos ;
			#include "UnityCG.cginc"
			// The MIT License
			// Copyright © 2013 Inigo Quilez
			// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

			
			float hash(float2 p)  
			{
				p  = 50.0*frac( p*0.3183099 + float2(0.71,0.113));
				return -1.0+2.0*frac( p.x*p.y*(p.x+p.y) );
			}

			float noise( in float2 p )
			{
				float2 i = floor( p );
				float2 f = frac( p );
	
				float2 u = f*f*(3.0-2.0*f);

				return lerp( lerp( hash( i + float2(0.0,0.0) ), 
								 hash( i + float2(1.0,0.0) ), u.x),
							lerp( hash( i + float2(0.0,1.0) ), 
								 hash( i + float2(1.0,1.0) ), u.x), u.y);
			}

			
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
											
			float smoothMin(float d1,float d2,float k)
			{
				return -log(exp(-k*d1)+exp(-k*d2))/k;
			}
						
			// Base distance function
			float ball(float3 p,float s)
			{
				return length(p)-s;
			}

			
			// Making ball status
			float4 metaballvalue(float i){
				float kt = 3*_Time.y*(0.1+0.01*i);
				float3 ballpos = 0.3*float3(noise(float2(i,i)+kt),noise(float2(i+10,i*20)+kt),noise(float2(i*20,i+20)+kt));
				float scale = 0.05+0.02*hash(float2(i,i));
				return  float4(ballpos,scale);
			}
			// Making ball distance function
			float metaballone(float3 p, float i){
				float3 ballpos = p-metaballvalue(i).xyz;
				float scale =metaballvalue(i).w;
				return  ball(ballpos,scale);
			}

			//Making metaballs distance function
			float metaball(float3 p){
			float d1;
			float pi = 0;
			float d2 =  metaballone(p,0);
			for (int i = 0; i < 6; ++i) {
				
				d1 = metaballone(p,i);
				d1 = smoothMin(d1,d2,20);
				d2 =d1;
				}
			return d1;
			}
		
		// Making distance function
			float dist(float3 p)
			{	
				float y = p.y;
				float d1 =metaball(p);
				float d2 = y-(_ypos); //For floor
			    d1 = smoothMin(d1,d2,20);
				return d1;
			}


			//enhanced sphere tracing  http://erleuchtet.org/~cupe/permanent/enhanced_sphere_tracing.pdf

			float raymarch (float3 ro,float3 rd)
			{
				
				
			float previousRadius = 0.02;
			float maxdistance = 3;
			float outside = dist(ro) < 0 ? -1 : +1;
			float pixelRadius = 0.02;
			float omega = 1.2;
			float t =0;
			float step = 0;
			float minpixelt =999999999;
			float mint = 0;
			float hit = 0.01;
				for (int i = 0; i < 60; ++i) {

					float Radius = outside*dist(ro+rd*t);
					bool fall = omega>1 &&step>(abs(Radius)+abs(previousRadius));
					if(fall){
						step -= step *omega;
						omega =0.8;
					}
					else{
						step = omega * Radius;
					}
					previousRadius = Radius;
					float pixelt = Radius/t;
					if(!fall&&pixelt<minpixelt){
						minpixelt = pixelt;
						mint = t;
					}
					if(!fall&&pixelt<pixelRadius||t>maxdistance)
					break;
					t += step;
				}
				
				if ((t > maxdistance || minpixelt > pixelRadius)&&(mint>hit)){
				return -1;
				}else{
				return mint;
				}
				
			}

			// The MIT License
			// Copyright © 2013 Inigo Quilez
			// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
			// https://www.shadertoy.com/view/Xds3zN

			//Tetrahedron technique  http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
			float3 getnormal( in float3 p){
				static const float2 e = float2(0.5773,-0.5773)*0.0001;
				float3 nor = normalize( e.xyy*dist(p+e.xyy) + e.yyx*dist(p+e.yyx) + e.yxy*dist(p+e.yxy ) + e.xxx*dist(p+e.xxx));
				nor = normalize(float3(nor));
				return nor ;
			}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// Making shadow
			float softray( float3 ro, float3 rd , float hn)
			{
				float t = 0.000001;
				float jt = 0.0;
				float res = 1;
				for (int i = 0; i < 20; ++i) {
					jt = dist(ro+rd*t);
					res = min(res,jt*hn/t);
					t = t+ clamp(0.02,2,jt);
				}
				return saturate(res);
			}
			// The MIT License
			// Copyright © 2013 Inigo Quilez
			// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
			// https://www.shadertoy.com/view/ld2GRz

			float4 material(float3 pos){
			
			float4 ballcol[6]={float4(0.5,0,0,1),
							float4(0.0,0.5,0,1),
							float4(0,0,0.5,1),
							float4(0.25,0.25,0,1),
							float4(0.25,0,0.25,1),
							float4(0.0,0.25,0.25,1)};
			float3 mate = float3(0,0,0);
			float w = 0.01;
			// Making ball color
			for (int i = 0; i < 6; ++i) {
				
				float x = clamp( (length( metaballvalue(i).xyz - pos )-metaballvalue(i).w)*10,0,1 ); 
				float p = 1.0 - x*x*(3.0-2.0*x);
				mate += p*float3(ballcol[i].xyz);
				w += p;

				}
			// Making floor color
			float x = clamp(  (pos.y-_ypos)*10,0,1 );
			float p = 1.0 - x*x*(3.0-2.0*x);
			mate += p*float3(0.1,0.1,0.1);
			w += p;
			 mate /= w;
			return float4(mate,1);
			}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			
			//Phong reflection model ,Directional light
			float4 lighting(float3 pos)
			{	
				float3 mpos =pos;
				float3 normal =getnormal(mpos);
				
				pos =  mul(unity_ObjectToWorld,float4(pos,1)).xyz;
				normal =  normalize(mul(unity_ObjectToWorld,float4(normal,0)).xyz);
					
				float3 ViewDir = normalize(pos-_WorldSpaceCameraPos);
				half3 lightdir = -normalize(float3(_WorldSpaceLightPos0.xyz));
				
				float sha = softray(mpos,lightdir,10);
				float4 Color = material(mpos);
				
				float NdotL = max(0,dot(normal,lightdir));
				float3 R = -normalize(reflect(lightdir,normal));
				float3 spec =pow(max(dot(R,-ViewDir),0),10);

				float4 col =  sha*(Color* NdotL+float4(spec,0));
				return col;
			}

			
		
				struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 pos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos= mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			struct pout
			{
				float4 pixel: SV_Target;
				float depth : SV_Depth;

			};

			pout frag (v2f i) 
			{
				float3 ro = mul( unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
				float3 rd = normalize(mul( unity_WorldToObject,float4(i.pos,1))-mul( unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz); // rd is ray direction/floattor
				float t = raymarch(ro,rd);
				fixed4 col;

				if (t==-1) {
				clip(-1);
				}
				else{
				float3 pos = ro+rd*t;
				col = lighting(pos);
				}
				pout o;
				o.pixel =col;
				float4 curp = mul(UNITY_MATRIX_P,mul(UNITY_MATRIX_MV,float4(ro+rd*t,1)));
				o.depth = (curp.z)/(curp.w); //Drawing depth

				return o;
				
			}
			ENDCG
		}
		
	}
}



