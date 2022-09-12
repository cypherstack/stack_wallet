abstract class GetUtxoSampleData {
  static const scriptHash0 =
      "477906c20249d06e4891c5c252957cdc4dd38b7932144a8b5407e2cdcdbf8be8";
  static const List<Map<String, dynamic>> utxos0 = [];

  static const scriptHash1 =
      "0d23f206295307df70e97534c4ceb92f82b4ebe7983342f8fd287071f90caf38";
  static const List<Map<String, dynamic>> utxos1 = [
    {
      "tx_pos": 0,
      "value": 45318048,
      "tx_hash":
          "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
      "height": 437146
    },
    {
      "tx_pos": 0,
      "value": 919195,
      "tx_hash":
          "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
      "height": 441696
    }
  ];
}

final batchUtxoRequest = {
  "843be6c3b2d3fafc8a4eca78b1e1226961a3572357d7486b3a596cfaaf25fce8": [
    "843be6c3b2d3fafc8a4eca78b1e1226961a3572357d7486b3a596cfaaf25fce8"
  ],
  "477906c20249d06e4891c5c252957cdc4dd38b7932144a8b5407e2cdcdbf8be8": [
    "477906c20249d06e4891c5c252957cdc4dd38b7932144a8b5407e2cdcdbf8be8"
  ],
  "c6e07f2a0eec2f50d2938b79e4e570d7edd1c83ae1f4512d2041a1c07d84f3b2": [
    "c6e07f2a0eec2f50d2938b79e4e570d7edd1c83ae1f4512d2041a1c07d84f3b2"
  ],
  "0d23f206295307df70e97534c4ceb92f82b4ebe7983342f8fd287071f90caf38": [
    "0d23f206295307df70e97534c4ceb92f82b4ebe7983342f8fd287071f90caf38"
  ]
};
