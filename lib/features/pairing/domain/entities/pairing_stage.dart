/// Stages of one pairing attempt, surfaced to the UI so it can react
/// without polling. Distinct from [PairingRepository.connectionStatus]
/// (which reflects only "is the encrypted data channel open right
/// now") -- this tracks the whole relay-mediated handshake leading up
/// to that point, including states connectionStatus alone can't
/// distinguish (waiting for a peer to join vs. actively negotiating,
/// or a peer leaving vs. the invite simply expiring).
enum PairingStage {
  idle,
  waitingForPeer, // invite created, no one has joined yet
  negotiating, // peer joined, exchanging keys/SDP/ICE
  connected, // data channel open
  peerLeft, // other side disconnected before completion
  expired, // invite's 10-minute TTL elapsed
  failed, // any other unrecoverable failure
}
