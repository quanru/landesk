#include "bridge_generated.h"

// Dart resolves these symbols dynamically. A discarded return value is optimized
// away in Release, so keep the generated symbol references observably live.
static volatile int64_t landesk_bridge_anchor;

void landesk_retain_native_bridge(void) {
    landesk_bridge_anchor = dummy_method_to_enforce_bundling();
}
