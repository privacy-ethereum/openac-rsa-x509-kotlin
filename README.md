[![](https://jitpack.io/v/privacy-ethereum/openac-rsa-x509-kotlin.svg)](https://jitpack.io/#privacy-ethereum/openac-rsa-x509-kotlin)

# OpenAC RSA X.509 Certificate Kotlin Library

Kotlin/Android bindings for the OpenAC zero-knowledge proof system that proves and verifies **RSA-X.509-Cert** — wrapping the mobile bindings built from the [`RSA-X.509-Cert`](https://github.com/privacy-ethereum/zkID/tree/RSA-X.509-Cert) branch of [zkID](https://github.com/privacy-ethereum/zkID) to expose `setupKeys` / `prove*` / `verify*` and related circuit helpers (cert_chain_rs4096, user_sig_rs2048) for proof generation and verification on Android, via UniFFI and JNI.

The prebuilt binaries are distributed via the [zkID RSA-X.509-Cert latest release](https://github.com/privacy-ethereum/zkID/releases/tag/RSA-X.509-Cert-latest).

## Requirements

- Android API 24+
- Android Studio / Gradle

## Installation

### JitPack

**Step 1.** Add the JitPack repository to your `settings.gradle.kts` at the end of repositories:

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

**Step 2.** Add the dependency to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.github.privacy-ethereum:openac-rsa-x509-kotlin:0.2.0")
}
```

Checkout the [JitPack page](https://jitpack.io/#privacy-ethereum/openac-rsa-x509-kotlin) for more available versions.

> **Note:** If you're using an Android template from `mopro create`, comment out these UniFFI dependencies in your build file to prevent duplicate class errors.
>
> ```kotlin
> // // Uniffi
> // implementation("net.java.dev.jna:jna:5.13.0@aar")
> // implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
> ```

## Example App

A complete example app is available at [privacy-ethereum/openac-taiwan-citizen-digital-certificate-android-example](https://github.com/privacy-ethereum/openac-taiwan-citizen-digital-certificate-android-example).

## Usage

Import the package and call the functions in order: `setupKeys` (optional) → `prove*` → `verify*`.

```kotlin
import uniffi.mopro.*
```

### 1. Setup Keys (Optional)

Generates proving and verifying keys for both circuits. **Skip this step if you already have the proving and verifying key files** — place them directly in `documentsPath/keys/` and proceed to `prove*`. Only run `setupKeys` if the key files are not yet present.

```kotlin
val documentsPath: String = context.filesDir.absolutePath

try {
    val message = setupKeys(documentsPath)
    println("Setup complete: $message")
} catch (e: ZkProofException) {
    println("Setup failed: $e")
}
```

Before calling `setupKeys`, download the required files and place them in `documentsPath`:

**R1CS files** (directly in `documentsPath/`):

| File                   | Download URL                                                                                                                        |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `certChainRS4096.r1cs` | [certChainRS4096.r1cs.gz](https://github.com/privacy-ethereum/zkID/releases/download/RSA-X.509-Cert-latest/certChainRS2048.r1cs.gz) |
| `userSigRS2048.r1cs`   | [userSigRS2048.r1cs.gz](https://github.com/privacy-ethereum/zkID/releases/download/RSA-X.509-Cert-latest/userSigRS2048.r1cs.gz)     |

**Key files** (in `documentsPath/keys/`):

| File                              | Download URL                                                                                                                                              |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cert_chain_rs4096_proving.key`   | [cert_chain_rs4096_proving.key.gz](https://github.com/privacy-ethereum/zkID/releases/download/RSA-X.509-Cert-latest/cert_chain_rs4096_proving.key.gz)     |
| `cert_chain_rs4096_verifying.key` | [cert_chain_rs4096_verifying.key.gz](https://github.com/privacy-ethereum/zkID/releases/download/RSA-X.509-Cert-latest/cert_chain_rs4096_verifying.key.gz) |
| `user_sig_rs2048_proving.key`     | [user_sig_rs2048_proving.key.gz](https://github.com/privacy-ethereum/zkID/releases/download/RSA-X.509-Cert-latest/user_sig_rs2048_proving.key.gz)         |
| `user_sig_rs2048_verifying.key`   | [user_sig_rs2048_verifying.key.gz](https://github.com/privacy-ethereum/zkID/releases/download/RSA-X.509-Cert-latest/user_sig_rs2048_verifying.key.gz)     |

The `.gz` key files must be decompressed before use (e.g. `gunzip *.gz`). The `.r1cs` files are also gzip-compressed — decompress them too.

You can also download all required files (R1CS, keys, and SMT snapshot) at once using the provided script:

```sh
bash scripts/download-test-vectors.sh
```

This downloads everything into `lib/src/androidTest/assets/TestVectors/`.

**Parameters:**

- `documentsPath` — directory containing the `.r1cs` files and the `keys/` subdirectory

**Returns:** a status string confirming completion.

---

### 2. Prove

Generate a zero-knowledge proof for a specific circuit. Both functions return a `ProofResult`.

```kotlin
// Certificate chain circuit (RS4096)
val certResult: ProofResult = proveCertChainRs4096(documentsPath)
println("Proved in ${certResult.proveMs} ms, size: ${certResult.proofSizeBytes} bytes")

// User signature circuit (RS2048)
val userResult: ProofResult = proveUserSigRs2048(documentsPath)
println("Proved in ${userResult.proveMs} ms, size: ${userResult.proofSizeBytes} bytes")
```

**Returns:** `ProofResult` with:

- `proveMs: ULong` — time taken to generate the proof in milliseconds
- `proofSizeBytes: ULong` — size of the generated proof in bytes

---

### 3. Verify

Verify the proof produced by the corresponding prove function.

```kotlin
// Verify individually
val certValid: Boolean = verifyCertChainRs4096(documentsPath)
val userValid: Boolean = verifyUserSigRs2048(documentsPath)

// Or verify both circuits together
val linked: Boolean = linkVerify(documentsPath)
```

**Returns:** `true` if the proof is valid, `false` otherwise.

---

### Generate Circuit Input

Use `generateCertChainRs4096Input` to produce JSON input files for both circuits from raw credential data.

> [!NOTE]
> `signedResponse` (and the accompanying `cert`) comes from the Taiwan FIDO service. Authenticate via [https://fido.moi.gov.tw/pt/](https://fido.moi.gov.tw/pt/) to obtain a response shaped like:
>
> ```json
> {
>     "error_code": "0",
>     "error_message": "SUCCESS",
>     "result": {
>         "hashed_id_num": "...",
>         "signed_response": "...",
>         "idp_checksum": "...",
>         "cert": "..."
>     }
> }
> ```
>
> Pass `result.signed_response` as `signedResponse` and `result.cert` (base64 DER) as `certb64`.

```kotlin
val outputPath: String = generateCertChainRs4096Input(
    certb64 = "<base64-encoded-cert>",
    signedResponse = "<signed-response-json>",
    tbs = "<tbs-data>",
    issuerCertPath = "/path/to/issuer.cer",
    smtSnapshotPath = "/path/to/g3-tree-snapshot.json.gz", // optional; pass null to skip SMT revocation
    outputDir = documentsPath,
    challenge = "<challenge-string>"
)
println("Input written to: $outputPath")
```

This writes two files into `outputDir`:

- `cert_chain_rs4096_input.json`
- `user_sig_rs2048_input.json`

**Parameters:**

- `smtSnapshotPath` — reserved for future revocation support; pass `null`
- `challenge` — challenge string included in the circuit input

---

### Benchmarking

Run the complete pipeline and get timing and size statistics for all stages:

```kotlin
val results: BenchmarkResults = runCompleteBenchmark(documentsPath)
println("Setup: ${results.setupMs} ms")
println("Prove: ${results.proveMs} ms")
println("Verify: ${results.verifyMs} ms")
println("Proving key: ${results.provingKeyBytes} bytes")
println("Verifying key: ${results.verifyingKeyBytes} bytes")
println("Proof: ${results.proofBytes} bytes")
println("Witness: ${results.witnessBytes} bytes")
```

---

### Full Example

```kotlin
import uniffi.mopro.*

suspend fun runZKProof(context: Context) {
    val documentsPath = context.filesDir.absolutePath

    try {
        // 1. Generate keys (run once; skip if keys already exist)
        val status = setupKeys(documentsPath)
        println("Keys ready: $status")

        // 2. Generate circuit inputs (with optional SMT revocation)
        val snapshotPath = "$documentsPath/g3-tree-snapshot.json.gz"
        generateCertChainRs4096Input(
            certb64 = "<base64-cert>",
            signedResponse = "<signed-response-json>",
            tbs = "<tbs>",
            issuerCertPath = "$documentsPath/MOICA-G3.cer",
            smtSnapshotPath = snapshotPath,
            outputDir = documentsPath,
            challenge = "<challenge-string>"
        )

        // 3. Generate proofs
        val certProof = proveCertChainRs4096(documentsPath)
        println("cert_chain proved in ${certProof.proveMs} ms (${certProof.proofSizeBytes} bytes)")

        val userProof = proveUserSigRs2048(documentsPath)
        println("user_sig proved in ${userProof.proveMs} ms (${userProof.proofSizeBytes} bytes)")

        // 4. Verify proofs
        val certValid = verifyCertChainRs4096(documentsPath)
        val userValid = verifyUserSigRs2048(documentsPath)
        val linked = linkVerify(documentsPath)
        println("cert_chain valid: $certValid")
        println("user_sig valid: $userValid")
        println("link verify: $linked")
    } catch (e: ZkProofException) {
        when (e) {
            is ZkProofException.SetupRequired -> println("Run setupKeys first: ${e.message}")
            is ZkProofException.FileNotFound -> println("Missing file: ${e.message}")
            is ZkProofException.InvalidInput -> println("Bad input: ${e.message}")
            is ZkProofException.ProofGenerationFailed -> println("Prove error: ${e.message}")
            is ZkProofException.VerificationFailed -> println("Verify error: ${e.message}")
            is ZkProofException.IoException -> println("IO error: ${e.message}")
        }
    } catch (e: Exception) {
        println("Unexpected error: $e")
    }
}
```

## API Reference

| Function                                                                                                            | Returns            | Description                                       |
| ------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------- |
| `setupKeys(documentsPath)`                                                                                          | `String`           | Generate keys for both circuits                   |
| `proveCertChainRs4096(documentsPath)`                                                                               | `ProofResult`      | Prove cert chain (RS4096) circuit                 |
| `proveUserSigRs2048(documentsPath)`                                                                                 | `ProofResult`      | Prove user signature (RS2048) circuit             |
| `verifyCertChainRs4096(documentsPath)`                                                                              | `Boolean`          | Verify cert chain proof                           |
| `verifyUserSigRs2048(documentsPath)`                                                                                | `Boolean`          | Verify user signature proof                       |
| `linkVerify(documentsPath)`                                                                                         | `Boolean`          | Verify both proofs together                       |
| `generateCertChainRs4096Input(certb64, signedResponse, tbs, issuerCertPath, smtSnapshotPath, outputDir, challenge)` | `String`           | Generate circuit input JSONs from credential data |
| `runCompleteBenchmark(documentsPath)`                                                                               | `BenchmarkResults` | Run full pipeline and return timing/size stats    |

## Error Handling

All throwing functions throw `ZkProofException`:

| Case                    | Description                                            |
| ----------------------- | ------------------------------------------------------ |
| `SetupRequired`         | `prove*` or `verify*` called before `setupKeys`        |
| `FileNotFound`          | A required file is missing from `documentsPath`        |
| `InvalidInput`          | The input JSON is malformed or missing required fields |
| `ProofGenerationFailed` | An error occurred during proof generation              |
| `VerificationFailed`    | The proof failed verification                          |
| `IoException`           | A filesystem read/write error occurred                 |

## Development

The bindings are built and uploaded to the [zkID RSA-X.509-Cert latest release](https://github.com/privacy-ethereum/zkID/releases/tag/RSA-X.509-Cert-latest) by the [`build-android-bindings`](https://github.com/privacy-ethereum/zkID/blob/8e599a73f2a43d8c2ecc4b62f32614efd220cedd/.github/workflows/mobile-tests.yaml#L196) job in zkID's CI. This produces `MoproAndroidBindings/uniffi/mopro.kt` and the native `.so` libraries under `MoproAndroidBindings/jniLibs`.

Download the bindings into this repo with:

```sh
./scripts/update_bindings.sh
```

which fetches the latest `MoproAndroidBindings.zip` release asset and copies `mopro.kt` and the `arm64-v8a` `.so` files into `lib/src/main/kotlin/uniffi/mopro` and `lib/src/main/jniLibs/arm64-v8a` respectively.

