import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

ImageProvider getProfileImageProvider(String? profilePic) {
  if (profilePic == null || profilePic.isEmpty) {
    return const AssetImage('assets/profile/profile.jpg');
  }
  try {
    // Try decoding as base64
    Uint8List bytes = base64Decode(profilePic);
    if (bytes.length > 100) {
      // Arbitrary threshold to avoid false positives
      return MemoryImage(bytes);
    }
  } catch (_) {
    // Not base64, treat as asset path
  }
  return AssetImage(profilePic);
}
