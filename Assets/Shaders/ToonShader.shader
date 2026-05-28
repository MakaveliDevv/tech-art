Shader "Custom/ToonShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _LightRamp("Light Ramp", 2D) = "white" {}
        _OutlineWidth("Outline Width", Float) = 0.1
        _MaxLineDistance("Line Distance", Float) = 100

        
        [HDR] _GlowColor("Glow Color", Color) = (0, 1, 1, 1)

        // _TrailStrength("Trail Strength", Range(0,5)) = 1
        _GlowStrength("Glow Strength", Range(0,5)) = 1.5
        _GlowPulseSpeed("Glow Pulse Speed", Range(0,10)) = 2
        _GlowPulseMin("Glow Pulse Min", Range(0,1)) = 0.6
        _GlowPulseMax("Glow Pulse Max", Range(0,5)) = 1.4
        _GlowAmplifier("Glow Amplifier", Range(0, 1)) = 0.05
        _GlowMovingIntensity("Glow Moving Intensity", Range(0,10)) = 0.3        
        _GlowIdleIntensity("Glow Idle Intensity", Range(0,10)) = 3
        _Velocity("Velocity", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "Queue"="Transparent" 
            "RenderPipeline" = "UniversalPipeline" 
        }
        
        Cull Front

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_LightRamp);
            SAMPLER(sampler_LightRamp);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;

                float4 _GlowColor;

                // float _TrailStrength;
                float _GlowStrength;
                float _GlowPulseSpeed;
                float _GlowPulseMin;
                float _GlowPulseMax;
                float _GlowAmplifier;
                float _GlowMovingIntensity;
                float _GlowIdleIntensity;

                float3 _Velocity;
            CBUFFER_END

            float _OutlineWidth;
            float _MaxLineDistance;

            float3 VertexAnimation(float3 worldPos, float3 normal, float2 uv)
            {
                return worldPos + normal * sin(_Time.y + uv.y * 12) * .125;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float4 clip = TransformObjectToHClip(IN.positionOS);

                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);

                // world space animation
                // worldPos = VertexAnimation(worldPos, IN.normal, IN.uv);

                // Fade outline based on Distance
                float depth = clip.w / _MaxLineDistance;
                float fallOff = 1.0 - saturate(depth);
                float width = _OutlineWidth * fallOff;

                // add normal to worldPos, based on Outline
                float3 worldNormal = TransformObjectToWorldNormal(IN.normal);
                worldPos += normalize(worldNormal) * width * clip.w;
                
                OUT.positionHCS = TransformWorldToHClip(worldPos);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {               
                // Movement Detection 
                float speed = length(_Velocity);
                float movementGlow = lerp 
                (
                    _GlowMovingIntensity, _GlowIdleIntensity,
                    saturate(1 - speed * _GlowAmplifier)
                );

                // Pulse animation
                float pulse = sin(_Time.y * _GlowPulseSpeed) * 0.5 + 0.5; // 0 to 1
                pulse = lerp(_GlowPulseMin, _GlowPulseMax, pulse);

                // Final glow strength
                float glow = movementGlow * pulse * _GlowStrength;

                float3 outlineColor = _GlowColor.rgb * glow;
                
                // return float4(0,0,0,1);
                return float4(outlineColor, 1);
            }
            ENDHLSL
        }

        Cull Back

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL0;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_LightRamp);
            SAMPLER(sampler_LightRamp);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;

                float4 _GlowColor;
                // float _TrailStrength;

                float _GlowStrength;
                float _GlowPulseSpeed;
                float _GlowPulseMin;
                float _GlowPulseMax;
                float _GlowAmplifier;
                float _GlowMovingIntensity;
                float _GlowIdleIntensity;

                float3 _Velocity;
            CBUFFER_END

            float3 VertexAnimation(float3 worldPos, float3 normal, float2 uv)
            {
                return worldPos + normal * sin(_Time.y + uv.y * 12) * .125;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                float3 pos = IN.positionOS.xyz;

                // object space animation

                float3 worldPos = TransformObjectToWorld(pos);

                
                float speed = length(_Velocity);
                float3 velocityDir = normalize(_Velocity + 0.0001);
                
                // Stronger effect on backside
                float smearMask = saturate(dot(normalize(IN.normal), -velocityDir));
                
                // worldPos -= velocityDir * smearMask * speed * _TrailStrength;
                worldPos -= velocityDir * speed;

                // world space animation
                // worldPos = VertexAnimation(worldPos, IN.normal, IN.uv);
                
                OUT.worldPos = worldPos;
                OUT.positionHCS = TransformWorldToHClip(worldPos);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = TransformObjectToWorldNormal(IN.normal);

                // float4 clip = TransformObjectToHClip(OUT.positionHCS);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.worldPos.xy ) * _BaseColor;

                // Normalize worldNormal
                float3 normal = abs(normalize(IN.normal));

                // Blend weights from world normal � force weights to sum to 1
                float3 blend = pow(normal, 8.0); // higher power = sharper transitions
                // This makes sure they add up to 1
                blend /= blend.x + blend.y + blend.z; // L1 normalize divide by sum of components, can also "/= dot(blend, 1.0)"

                // Sample texture from each axis
                float4 xSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.worldPos.yz);
                float4 ySample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.worldPos.xz);// + frac(float2(_Time.y,_Time.y)));
                float4 zSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.worldPos.xy);

                // Blend
                float4 color = xSample * blend.x + ySample * blend.y + zSample * blend.z;

                // Alpha Clipping
                // clip(color.a - 0.5);

                // Bypass GetMainLight entirely and sample raw shadow map
                float4 shadowCoord = TransformWorldToShadowCoord(IN.worldPos);
                Light mainLight = GetMainLight(shadowCoord);
                float light = dot(IN.normal, mainLight.direction) * .5 + .5;
                float shadow = mainLight.shadowAttenuation; //MainLightRealtimeShadow(shadowCoord); //read shadow map directly
                float lighting = light * shadow;
    
                // NdotViewDir, results in stable value for V
                float rampV = dot(IN.normal, normalize(GetWorldSpaceViewDir(IN.worldPos))) * 0.5 + 0.5;

                float4 LightSample = SAMPLE_TEXTURE2D(_LightRamp, sampler_LightRamp, float2(light, rampV));

                // sample spherical harmonics for the environment
                float3 ambientUp = SampleSH(float3(0, 1, 0));  // 100% day colour
                float3 ambientDn = SampleSH(float3(0, -1, 0)); // 100% night colour

                float upness = dot(normalize(-mainLight.direction), float3(0,1,0)) * 0.5 + 0.5;
                float nightNess = saturate( ( 1.0 - upness ) * 2 - .5);
                float3 ambient = lerp(ambientUp, ambientDn, nightNess);

                // Rim lighting based on view direction
                float3 viewDir = normalize(GetWorldSpaceViewDir(IN.worldPos));
                float rim = 1.0 - saturate(dot(viewDir, normalize(IN.normal)));
                rim = pow(rim, 4);

                // Movement glow reduction
                float speed = length(_Velocity);
                float movementGlow = lerp
                (
                    _GlowMovingIntensity, _GlowIdleIntensity,
                    saturate(1 - speed * _GlowAmplifier)
                );
                
                float pulse = sin(_Time.y * _GlowPulseSpeed) * 0.5 + 0.5; // 0 to 1
                pulse = lerp(_GlowPulseMin, _GlowPulseMax, pulse);

                // Final glow strength
                float glow = rim * movementGlow * pulse * _GlowStrength * _GlowColor.rgb;
                
                float4 finalColor = 
                    color * 
                    float4(mainLight.color, 1) *
                    nightNess *
                    min(LightSample.r * lighting * ambient.r, 1);

                // Added glow
                finalColor.rgb += glow;

                return finalColor;
                
                // return color * float4(mainLight.color, 1) * nightNess * min(LightSample.r * lighting + ambient.r, 1);// + float4(ambient,1) * nightNess;
            }
            ENDHLSL
        }

        // Easy enough to add shadow!
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
