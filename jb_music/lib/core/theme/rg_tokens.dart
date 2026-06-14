// lib/core/theme/rg_tokens.dart
//
// BACKWARD COMPATIBILITY SHIM
// All existing code that imports rg_tokens.dart continues to work unchanged.
// All RG.xxx references now resolve to the new NOVA design system.
//
// The real implementation lives in jb_design_system.dart

export 'jb_design_system.dart' show
    RG,
    RGTokens,
    JBColors,
    JBSpacing,
    JBRadius,
    JBType,
    JBShadow,
    JBGlass,
    JBGradients,
    JBDecor,
    JBAnim,
    JBTheme;
