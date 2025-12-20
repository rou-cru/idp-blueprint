# GitHub Actions CI/CD Strategy

- The logic have to reuse the Task avaliable when possible
- Its better use an Action available in Github than implement custom logic
- Should me as modular as posible to reuse logic from steps but efficient in the use of runners
- The main branch its the complete pipeline process for CICD in the proyect, all extra scenarios should be a subpipeline from this one.
- Pull Request should trigger GA just if make sense because the changes in the PR to avoid waste Runner's time.

## "The Grand Pipeline"

```mermaid
graph TD

    Start([Push/Merge to Main])
    Gate_Sec{Leak Detected?}
    Stop((Failed))
    Badge_Infra(Demo Quality)
    Badge_Portal(Portal Status)
    Badge_Devbox(Devbox Status)
    Badge_Ops(Ops Status)
    Badge_Docs(Docs Deployment)

    subgraph secrets-gate
        SQ_1[Checkout] --> SQ_2{{Trufflehog}}
    end

    subgraph scan-iac
        IQ_3{{Trivy Config}}
    end

    subgraph stream-infra
        IQ_1[Checkout] --> IQ_2[Linting] --> scan-iac
    end

    subgraph scan-deps-back [scan-deps]
        BQ_2{{Yarn Audit}}
    end

    subgraph scan-sast
        BQ_3{{CodeQL}}
    end

    subgraph scan-artifact-back [scan-artifact]
        BQ_7{{Trivy Image}}
    end

    subgraph supply-chain-back [supply-chain]
        BQ_8[[Generate SBOM]] --> BQ_9[[Sign Artifact]]
    end

    subgraph stream-backstage
        BQ_1[Checkout]
        scan-deps-back
        scan-sast
        BQ_4[[App Build]]
        BQ_5[[App Test]]
        BQ_6[[Docker Build]]
        scan-artifact-back
        supply-chain-back
        BQ_10((Push))
    end

    subgraph scan-artifact-dev [scan-artifact]
        DQ_3{{Trivy Image}}
    end

    subgraph supply-chain-dev [supply-chain]
        DQ_4[[Generate SBOM]] --> DQ_5[[Sign Artifact]]
    end

    subgraph stream-devbox
        DQ_1[Checkout] --> DQ_2[[Docker Build]] --> scan-artifact-dev --> supply-chain-dev --> DQ_6((Push))
    end

    subgraph scan-artifact-ops [scan-artifact]
        OQ_3{{Trivy Image}}
    end

    subgraph supply-chain-ops [supply-chain]
        OQ_4[[Generate SBOM]] --> OQ_5[[Sign Artifact]]
    end

    subgraph stream-ops
        OQ_1[Checkout] --> OQ_2[[Docker Build]] --> scan-artifact-ops --> supply-chain-ops --> OQ_6((Push))
    end

    subgraph scan-deps-docs [scan-deps]
        Docs_2{{Audit}}
    end

    subgraph stream-docs
        Docs_1[Checkout] --> scan-deps-docs --> Docs_3[Linting] --> Docs_4[[Build Site]] --> Docs_5((Deploy))
    end

    Start --> secrets-gate
    secrets-gate --> Gate_Sec
    Gate_Sec -- No --> IQ_1
    Gate_Sec -- No --> BQ_1
    Gate_Sec -- No --> DQ_1
    Gate_Sec -- No --> OQ_1
    Gate_Sec -- No --> Docs_1
    BQ_1 --> scan-deps-back
    scan-deps-back --> scan-sast
    scan-sast --> BQ_4
    BQ_4 --> BQ_5
    BQ_5 --> BQ_6
    BQ_6 --> scan-artifact-back
    scan-artifact-back --> supply-chain-back
    supply-chain-back --> BQ_10
    Gate_Sec -- Yes --> Stop
    scan-iac -.- Badge_Infra
    BQ_10 -.- Badge_Portal
    DQ_6 -.- Badge_Devbox
    OQ_6 -.- Badge_Ops
    Docs_5 -.- Badge_Docs
```


## Blueprint de Arquitectura a detalle para implementacion en GA



```mermaid
graph LR
  E((Event)) --> SG{{Secrets gate job}} --> CH{{Changes job}}
  SG -- fail --> STOP((Stop))

  CH -- main --> ALL[All run flags true] --> OUT[Decision outputs]
  CH -- PR --> PATHS[Run flags by paths] --> OUT

  OUT --> JDOCS([Job docs]) --> RD[(Runner A)] --> D1[Checkout] --> D2[Cache audit] --> D3[Lint] --> D4[Build] --> D5{is main}
  D5 -- yes --> D6[Deploy]
  D5 -- no --> D7[Skip]

  OUT --> JPORTAL([Job portal]) --> RP[(Runner B)] --> P1[Checkout] --> P2[Cache install] --> P3[Lint test] --> P4[Build] --> P5[Docker build] --> P6[Scan] --> P7[SBOM] --> P8[Sign] --> P9{is main}
  P9 -- yes --> P10[Push]
  P9 -- no --> P11[Skip]

  OUT --> JINFRA([Job infra]) --> RI[(Runner C)] --> I1[Checkout] --> I2[Lint yaml] --> I3[Validate k8s] --> I4[Scan IaC] --> I5[Consistency]

  OUT --> JOPS([Job ops]) --> RO[(Runner D)] --> O1[Checkout] --> O2[Docker build] --> O3[Scan] --> O4[SBOM] --> O5[Sign] --> O6{is main}
  O6 -- yes --> O7[Push]
  O6 -- no --> O8[Skip]

  OUT --> JDEVBOX([Job devbox]) --> RV[(Runner E)] --> V1[Checkout] --> V2[Docker build] --> V3[Scan] --> V4[SBOM] --> V5[Sign] --> V6{is main}
  V6 -- yes --> V7[Push]
  V6 -- no --> V8[Skip]
```
