# Apple Compliance Notes

FCB iOS support must stay inside Apple's allowance for interpreted code. This is an engineering checklist, not legal advice.

## Constraints

- Patch payloads must be data for the bundled interpreter, not downloaded native code.
- Patch execution must not change the app's primary purpose.
- Patch execution must not bypass App Review, sandboxing, code signing, privacy prompts, or platform security controls.
- The app must keep working when the server is unreachable or a patch is rejected locally.
- All patch payloads must be signed and verified before install.

## Reviewer Notes

Use reviewer notes that describe the mechanism plainly:

- The app downloads signed FCB bytecode data.
- The bytecode is interpreted by code already bundled in the submitted app.
- The bytecode is scoped to app-owned business logic and cannot install executable binaries.
- A last-known-good rollback path disables failed patches automatically.

## Evidence To Keep

- TestFlight build number and engine commit.
- Patch manifest and payload hash.
- Signature key id and verification result.
- Device drill logs proving baseline, patched launch, and rollback.
- Server `patch_events` rows for `install`, `launch_success`, `launch_failure`, and `crash_rollback`.

## Rejection Handling

If App Review rejects the build:

1. Preserve the exact reviewer message.
2. Map the cited guideline to a concrete payload or runtime behavior.
3. Disable iOS rollout for the affected channel while investigating.
4. If the issue is payload scope, reduce the bytecode surface and resubmit.
5. If the issue is interpreted-code policy, prepare an appeal with the evidence above.
