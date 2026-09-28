/// Markers carried inside mock ciphertext, never as envelope JSON fields.
///
/// File names, sizes, and audio bytes are not part of these markers. They
/// stay in the in-memory UI catalog and are not written to the wire payload.
const wallSmileyPayload = '\u{F8FF}kind:wall-smiley';
const filePayload = '\u{F8FF}kind:file';
const voicePayload = '\u{F8FF}kind:voice';
