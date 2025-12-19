# GitHub Actions CI/CD Strategy

## The "Grand Pipeline" (Atomic File & Execution)

**Shapes:**
- `{{Hexagon}}`: Policy / Security
- `[[Double Rectangle]]`: Build / Process
- `[Rectangle]`: Setup / Atomic Action
- `((Circle))`: Delivery
- `(Stadium)`: Status / Badge / Trigger
- `Box`: Physical File Context

```mermaid
graph TD
    %% =========================================================
    %% TRIGGER (EVENT)
    %% =========================================================
    Start([Push/Merge to Main])

    %% =========================================================
    %% SECURITY GATE
    %% =========================================================
    Start --> SQ_1
    
    subgraph secrets-gate.yaml
        SQ_1[Checkout] --> SQ_2{{Trufflehog}}
    end

    SQ_2 --> Gate_Sec{Leak Detected?}

    %% =========================================================
    %% PARALLEL STREAMS (Workflow Files)
    %% =========================================================
    
    Gate_Sec -- No --> IQ_1
    Gate_Sec -- No --> BQ_1
    Gate_Sec -- No --> DQ_1
    Gate_Sec -- No --> OQ_1
    Gate_Sec -- No --> Docs_1

    %% INFRASTRUCTURE
    subgraph stream-infra.yaml
        IQ_1[Checkout] --> IQ_2[Linting]
        IQ_2 --> scan-iac
        
        subgraph scan-iac
            IQ_3{{Trivy Config}}
        end
    end

    %% BACKSTAGE
    subgraph stream-backstage.yaml
        BQ_1[Checkout] --> scan-deps-back
        
        subgraph scan-deps-back [scan-deps]
            BQ_2{{Yarn Audit}}
        end
        
        scan-deps-back --> scan-sast
        
        subgraph scan-sast
            BQ_3{{CodeQL}}
        end
        
        scan-sast --> BQ_4[[App Build]]
        BQ_4 --> BQ_5[[App Test]]
        BQ_5 --> BQ_6[[Docker Build]]
        BQ_6 --> scan-artifact-back
        
        subgraph scan-artifact-back [scan-artifact]
            BQ_7{{Trivy Image}}
        end
        
        scan-artifact-back --> supply-chain-back
        
        subgraph supply-chain-back [supply-chain]
            BQ_8[[Generate SBOM]] --> BQ_9[[Sign Artifact]]
        end
        
        supply-chain-back --> BQ_10((Push))
    end

    %% DEVBOX
    subgraph stream-devbox.yaml
        DQ_1[Checkout] --> DQ_2[[Docker Build]]
        DQ_2 --> scan-artifact-dev
        
        subgraph scan-artifact-dev [scan-artifact]
            DQ_3{{Trivy Image}}
        end
        
        scan-artifact-dev --> supply-chain-dev
        
        subgraph supply-chain-dev [supply-chain]
            DQ_4[[Generate SBOM]] --> DQ_5[[Sign Artifact]]
        end
        
        supply-chain-dev --> DQ_6((Push))
    end

    %% OPS
    subgraph stream-ops.yaml
        OQ_1[Checkout] --> OQ_2[[Docker Build]]
        OQ_2 --> scan-artifact-ops
        
        subgraph scan-artifact-ops [scan-artifact]
            OQ_3{{Trivy Image}}
        end
        
        scan-artifact-ops --> supply-chain-ops
        
        subgraph supply-chain-ops [supply-chain]
            OQ_4[[Generate SBOM]] --> OQ_5[[Sign Artifact]]
        end
        
        supply-chain-ops --> OQ_6((Push))
    end

    %% DOCUMENTATION
    subgraph stream-docs.yaml
        Docs_1[Checkout] --> scan-deps-docs
        
        subgraph scan-deps-docs [scan-deps]
            Docs_2{{Audit}}
        end
        
        scan-deps-docs --> Docs_3[Linting]
        Docs_3 --> Docs_4[[Build Site]]
        Docs_4 --> Docs_5((Deploy))
    end

    %% FAIL STATE
    Gate_Sec -- Yes --> Stop((Failed))

    %% =========================================================
    %% MONITORING
    %% =========================================================
    
    scan-iac -.- Badge_Infra(Demo Quality)
    BQ_10 -.- Badge_Portal(Portal Status)
    DQ_6 -.- Badge_Devbox(Devbox Status)
    OQ_6 -.- Badge_Ops(Ops Status)
    Docs_5 -.- Badge_Docs(Docs Deployment)
```