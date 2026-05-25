[![](https://jitpack.io/v/zkmopro/OpenACKotlin.svg)](https://jitpack.io/#zkmopro/OpenACKotlin)

# OpenACKotlin

A Kotlin/Android library for generating and verifying zero-knowledge proofs for two RS circuits (`cert_chain_rs4096` and `device_sig_rs2048`) using native Rust code via UniFFI and JNI.

## Getting OpenACKotlin via JitPack

To get this library from GitHub using [JitPack](https://jitpack.io/#zkmopro/OpenACKotlin):

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
    implementation("com.github.zkmopro:OpenACKotlin:0.2.0")
}
```

Checkout the [JitPack page](https://jitpack.io/#zkmopro/OpenACKotlin) for more available versions.

**Note:** If you're using an Android template from `mopro create`, comment out these UniFFI dependencies in your build file to prevent duplicate class errors.

```kotlin
// // Uniffi
// implementation("net.java.dev.jna:jna:5.13.0@aar")
// implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
```

## API Reference

All functions are in the `uniffi.mopro` package. The library supports two circuits:
- **`cert_chain_rs4096`** — Certificate chain verification
- **`device_sig_rs2048`** — Device signature verification

### Import the package

```kotlin
import uniffi.mopro.generateCertChainRs4096Input
import uniffi.mopro.setupKeys
import uniffi.mopro.proveCertChainRs4096
import uniffi.mopro.proveDeviceSigRs2048
import uniffi.mopro.verifyCertChainRs4096
import uniffi.mopro.verifyDeviceSigRs2048
import uniffi.mopro.linkVerify
import uniffi.mopro.runCompleteBenchmark
import uniffi.mopro.BenchmarkResults
import uniffi.mopro.ProofResult
import uniffi.mopro.ZkProofException
```

### `generateCertChainRs4096Input`

Generates JSON input files for both circuits from raw certificate data.

```kotlin
val status: String = generateCertChainRs4096Input(
    certb64 = "<base64-encoded certificate>",
    signedResponse = "<signed response string>",
    tbs = "<to-be-signed data>",
    issuerCertPath = "/path/to/issuer.crt",
    smtSnapshotPath = null,     // optional path to g3-tree-snapshot.json.gz; pass null to skip SMT revocation
    outputDir = context.filesDir.absolutePath,
    challenge = "<challenge-string>"
)
```

Writes two files to `outputDir`:
- `cert_chain_rs4096_input.json`
- `device_sig_rs2048_input.json`

Returns a status string on success. Throws `ZkProofException` on failure.

### Downloading Pre-built Keys

Instead of generating keys locally with `setupKeys`, you can download pre-built keys from the [zkID releases](https://github.com/zkmopro/zkID/releases/download/latest/) and place them in `documentsPath/keys/`.

Download and extract the following files:

| File | Download URL |
|---|---|
| `cert_chain_rs4096_proving.key` | [`cert_chain_rs4096_proving.key.gz`](https://github.com/zkmopro/zkID/releases/download/latest/cert_chain_rs4096_proving.key.gz) |
| `cert_chain_rs4096_verifying.key` | [`cert_chain_rs4096_verifying.key.gz`](https://github.com/zkmopro/zkID/releases/download/latest/cert_chain_rs4096_verifying.key.gz) |
| `user_sig_rs2048_proving.key` | [`user_sig_rs2048_proving.key.gz`](https://github.com/zkmopro/zkID/releases/download/latest/user_sig_rs2048_proving.key.gz) |
| `user_sig_rs2048_verifying.key` | [`user_sig_rs2048_verifying.key.gz`](https://github.com/zkmopro/zkID/releases/download/latest/user_sig_rs2048_verifying.key.gz) |

After extracting, place all `.key` files into `documentsPath/keys/`. Example using `OkHttp` and `GZIPInputStream`:

```kotlin
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.util.zip.GZIPInputStream

suspend fun downloadKeys(documentsPath: String) {
    val keysDir = File(documentsPath, "keys").also { it.mkdirs() }
    val client = OkHttpClient()
    val baseUrl = "https://github.com/zkmopro/zkID/releases/download/latest"

    val files = listOf(
        "cert_chain_rs4096_proving.key",
        "cert_chain_rs4096_verifying.key",
        "user_sig_rs2048_proving.key",
        "user_sig_rs2048_verifying.key"
    )

    for (name in files) {
        val dest = File(keysDir, name)
        if (dest.exists()) continue
        val response = client.newCall(Request.Builder().url("$baseUrl/$name.gz").build()).execute()
        GZIPInputStream(response.body!!.byteStream()).use { input ->
            dest.outputStream().use { output -> input.copyTo(output) }
        }
    }
}
```

You can also download all required files (R1CS, keys, and SMT snapshot) at once using the provided script:

```sh
bash scripts/download-test-vectors.sh
```

This downloads everything into `lib/src/androidTest/assets/TestVectors/`.

### `setupKeys`

Alternatively, generate keys locally from R1CS files. Requires `cert_chain_rs4096.r1cs` and `device_sig_rs2048.r1cs` to be present in `documentsPath`. This is slow and only needed if you cannot use the pre-built keys above.

```kotlin
val documentsPath: String = context.filesDir.absolutePath

val result: String = setupKeys(documentsPath)
```

Returns a status string on success. Throws `ZkProofException` on failure.

### `proveCertChainRs4096`

Generates a ZK proof for the `cert_chain_rs4096` circuit. Reads `cert_chain_rs4096_input.json` from `documentsPath`.

```kotlin
val result: ProofResult = proveCertChainRs4096(documentsPath)
println("Prove time: ${result.proveMs} ms")
println("Proof size: ${result.proofSizeBytes} bytes")
```

### `proveDeviceSigRs2048`

Generates ZK proofs for both the `cert_chain_rs4096` and `device_sig_rs2048` circuits. Reads both input JSON files from `documentsPath`.

```kotlin
val result: ProofResult = proveDeviceSigRs2048(documentsPath)
println("Prove time: ${result.proveMs} ms")
println("Proof size: ${result.proofSizeBytes} bytes")
```

**`ProofResult` fields:**

| Field | Type | Description |
|---|---|---|
| `proveMs` | `ULong` | Time to generate the proof in milliseconds |
| `proofSizeBytes` | `ULong` | Size of the proof in bytes |

Both prove functions throw `ZkProofException.SetupRequired` if keys have not been set up yet.

### `verifyCertChainRs4096`

Verifies the proof for the `cert_chain_rs4096` circuit stored in `documentsPath`.

```kotlin
val isValid: Boolean = verifyCertChainRs4096(documentsPath)
```

### `verifyDeviceSigRs2048`

Verifies the proof for the `device_sig_rs2048` circuit stored in `documentsPath`.

```kotlin
val isValid: Boolean = verifyDeviceSigRs2048(documentsPath)
```

### `linkVerify`

Verifies proofs for both circuits together.

```kotlin
val isValid: Boolean = linkVerify(documentsPath)
```

All verify functions return `true` if the proof is valid, `false` otherwise. Throws `ZkProofException` on error.

### `runCompleteBenchmark`

Runs the full pipeline (setup → prove → verify) for both circuits and returns timing and size metrics.

```kotlin
val results: BenchmarkResults = runCompleteBenchmark(documentsPath)
println("Setup:    ${results.setupMs} ms")
println("Prove:    ${results.proveMs} ms")
println("Verify:   ${results.verifyMs} ms")
println("Proving key:   ${results.provingKeyBytes} bytes")
println("Verifying key: ${results.verifyingKeyBytes} bytes")
println("Proof:         ${results.proofBytes} bytes")
println("Witness:       ${results.witnessBytes} bytes")
```

**`BenchmarkResults` fields:**

| Field | Type | Description |
|---|---|---|
| `setupMs` | `ULong` | Time for key setup in milliseconds |
| `proveMs` | `ULong` | Time for proof generation in milliseconds |
| `verifyMs` | `ULong` | Time for verification in milliseconds |
| `provingKeyBytes` | `ULong` | Size of the proving key in bytes |
| `verifyingKeyBytes` | `ULong` | Size of the verifying key in bytes |
| `proofBytes` | `ULong` | Size of the proof in bytes |
| `witnessBytes` | `ULong` | Size of the witness in bytes |

### Error Handling

All functions (except the verify functions) throw `ZkProofException` on failure. The sealed class variants are:

| Variant | Description |
|---|---|
| `ZkProofException.FileNotFound` | A required file could not be found |
| `ZkProofException.ProofGenerationFailed` | Proof generation encountered an error |
| `ZkProofException.VerificationFailed` | Proof verification encountered an error |
| `ZkProofException.InvalidInput` | The provided input is invalid |
| `ZkProofException.SetupRequired` | Keys must be set up before proving |
| `ZkProofException.IoException` | An I/O error occurred |

```kotlin
try {
    val proof = proveCertChainRs4096(documentsPath)
} catch (e: ZkProofException.SetupRequired) {
    // Run setupKeys first
} catch (e: ZkProofException) {
    println("ZK error: ${e.message}")
}
```

## Usage Example

```kotlin
import uniffi.mopro.*

val documentsPath = context.filesDir.absolutePath

// 1. Generate circuit inputs from certificate data
generateCertChainRs4096Input(
    certb64 = certBase64,
    signedResponse = signedResponse,
    tbs = tbs,
    issuerCertPath = issuerCertPath,
    smtSnapshotPath = null,
    outputDir = documentsPath,
    challenge = challenge
)

// 2. Download pre-built keys (only needed once)
downloadKeys(documentsPath)
// Or generate locally: setupKeys(documentsPath)

// 3. Generate proofs
val certProof = proveCertChainRs4096(documentsPath)
println("cert_chain proved in ${certProof.proveMs} ms")

val deviceProof = proveDeviceSigRs2048(documentsPath)
println("device_sig proved in ${deviceProof.proveMs} ms")

// 4. Verify proofs
val valid = linkVerify(documentsPath)
println("Proofs valid: $valid")
```

## How to Build the Package

This package relies on bindings generated by the Mopro CLI.
To learn how to build Mopro bindings, refer to the [Getting Started](https://zkmopro.org/docs/getting-started) section.

Use `mopro-cli` and choose the appropriate circuit:

```sh
mopro init
mopro build
```

Choose `android` and build for `aarch64-linux-android` and `x86_64-linux-android` architectures.

Then replace the bindings in:

- `lib/src/main/java/uniffi`
- `lib/src/main/jniLibs`

Or copy them with:

```sh
cp -r MoproAndroidBindings/uniffi lib/src/main/java
cp -r MoproAndroidBindings/jniLibs lib/src/main
```

## Community

- X account: <a href="https://twitter.com/zkmopro"><img src="https://img.shields.io/twitter/follow/zkmopro?style=flat-square&logo=x&label=zkmopro"></a>
- Telegram group: <a href="https://t.me/zkmopro"><img src="https://img.shields.io/badge/telegram-@zkmopro-blue.svg?style=flat-square&logo=telegram"></a>

## Acknowledgements

This work was initially sponsored by a joint grant from [PSE](https://pse.dev/) and [0xPARC](https://0xparc.org/). It is currently incubated by PSE.
