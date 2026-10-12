#import <OrangeLenResources/OrangeLenResources-Swift.h>

// A real symbol reference retains the shared framework under dead stripping.
// Loading it exposes its resource anchor before any reader/localization starts.
__attribute__((constructor)) static void OrangeLenLoadResourceFramework(void) {
    (void)[OrangeLenResourceAnchor class];
}
