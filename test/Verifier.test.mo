import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import M "mo:matchers/Matchers";
import { run; suite; testLazy } "mo:matchers/Suite";
import T "mo:matchers/Testable";
import Hex "mo:merkle-patricia-trie/util/Hex";
import Value "mo:merkle-patricia-trie/Value";
import RLP "mo:rlp";

import Verifier "../src/Verifier";

let storageHash = "5ca849758d8f9a0a463f3cff7d06516f69381c8cefba697e8f95a3c0a965df12";
let key = "c92c3a279814545c4590501add24843ce5413758f3869cb4885635cbbdbbaa51";
let proof = [
  "f90211a0785fb1aac3effe50f253e714289554b9683763e0feaa27053a2c2be9fe4422d8a0308d39234d4618f3ff4d071f3a753bd18cfcd033b9d6b789a048ea49352d850ba0d9a6aee1c9aee3050b067495f03337321be9a505433f30fefabd20d35ac420bfa08abe82b28ea441af3aaa217e716003baca47132cca259863c9c6d37f69882d0ea0ce351f31097c3f5e3accbe5023a82ea7235dab300f4725bc77ec2a5bb7b4ed9fa07bf49b0f46631246e9c0e6e0086d416398ecbb2fe57cf2d4c65bb7434305f4cea0a9f5036e90e42c9a316aaf613c5dbd86a14c2ede3783fa73d3623f8df12eb1a6a0df73bcd2634554d5f580f7073ff6cd97ba5d91ec259dbeba9835e9450d1fa60ba064ae98b7852643286729d44b9197ab4dab474c63500439df691cab476f9c4ed2a0c4be110809ea44d9da1064e4b1c3e41ec0919c53fd99c3065d1fecf6dc6cf3d4a0953845cbda208b5d36b0228b7f73fbe6eedee1f8558b7a8679b1b365b848d903a0b3a76090256962ddae86d69c0459feb7e1aae7e3c88696359365e594bbf2f7e3a0b52a25a8b9ad8b787f1a2e597841bebc252f42bdb4872c8699f8c9b12af6121ba000755ec2f3b4d8f6199c7923f2b12e38f105e829dc640be94d2e732c2446af2fa0ecbf2df4fdf9fe8e2e47654f1a0f442c5fd4ae60aa773515450f5a89b964fa94a001956376c446df4473d3b5b34a033ba7d9fa213b188bd67de753d3c718f0e37c80",
  "f90211a0b619bf636e87ee05963892e8ea75a90f7350e319cf60f26b1e6754973a0b7240a09c55d28f7e33727466f91e31ad99dacfcbea9a79a1b0d6cca9fa1f04c7a8d2a1a06911fb115d29f00fdca92f02dd1e24d01a781e8bdfc8426572d2e3923a605999a0b24c0d6dab13c42bb03c2e4970ca793d0da69549f33fa34318407757dfef3af8a09f57d9d0a19b567643996510b2ffbe2b7f4877ca7b5e048060385ea00cc04801a0b57c265e62639286edd18f56191e48a808a550b90c6f1eca9af14f748d299484a0ec22222e31a091d74a4c1a407e2b3162c3d85e6c47f08bc26de37ce79e01666da0d9ce552baf1958f29c47ab3d621b76429f0a5fe178f5c240d20e6f607ec62feba054bff79676c69b781d956a678c94d783d7ea91174ebc93a1422a04f09c4841cba03d1388529362d09d2ef2e564ab5c94df0702310b4bbe14d7c759be65465b0bfca0be822b339ab79f6ff5a6f020a9e2695d0d5aa8dd45151ff7b9447f0b65d76913a029616bb932e230ccde718cd7b1e80bdba9d07868796a3d9bf74c0810153b020ea0c9086e05d92be496888f79d825ecfc7da818fa8304535e87100d78e03f13cfcaa0f879be5fdc0f3fc84e0bb6a29b381e401d30081bc8beab7676d5e7e2bd398917a0884ad10eba4450db0b568d373a5de7d9ee79e8fe01ec76f858e9f7be80e74428a0fa07b140480643cb0015689241ef95df46ac7e28492d0f98b91a4129e6022dd280",
  "f90211a0d5174b9d7c37faed3852ed1842bf7c64aa2460ef74d1192775904658109d7054a050109bdbd4c02759bb088876574863cbd8bb3f85deb8b6bec4cb1f4a733d8421a0b35bab85d64d676650c3b9c4bb4b6b156152d8ec28faa4afdb61a2bd05df1136a05015df553c6594090aabe7cd1a3ae2f6539e2b67313b29c513a80fbb49c01037a07f51f76af24e73a9ac86715f61e8e53d1f305a012b61f9c3f4d8ea994b03b99ba082db289c3c7076257686ca90124677a49c3a4f07110c041e80262cac8432ecf2a0127229ee7595f49ee8ffb41311bfad9fa6a030ed94acf367f37052367fcef3e8a0a801c5a7f6ff64f985a52dbd559297b6fc6383b8208ea60623e2412466795ef9a0f2183ec683d20117aeada6d655af07a6556e8e6f20337a4b4d5f8ba91f6c66d4a06df02e478ca6f3cb0207345013d969e5d0fdcf24a0d6e53699d0790a1b06cc6aa0428613a90544be7be934cc08d3c5ea65ca4791d28fb0a30f9caa1315ac8a7bf4a0ae54f61b3e9daa0091c0e6a532dbe0484ec13f4702e836cbb98707f5e8f73097a0986029d508b19ea3b83740fd388ae761d9d21270314a48e81f0ba3003391805fa056cd66f47cd16b249b8464f30fc8438f343f065b40aea51168f181b2e48522f1a0ffb7ac6d74366b0dd94f6c6017b7e423f59c1af4cb044b00a2c894495adbf609a020b697d291b574fd3b4b1617afdc071c849381475858fb367d0dd48878bfd1c780",
  "f90211a07ff1bfcb5699d3f95cb969f2f05f66170af2553c032bef31ce0c48564ca91524a003004cac1b7288b4bea259d7e54729771f219d09ebcb76118bd136e60ca69bb9a034b80e92698ff72b57da0afb8029dd9fafea02ee3bf41fe5506e4a86490214b4a09937f146a301e2dbf8a61680a0e177840eddba59dfd4c6846b877d02360da675a0e5f31a19f6bd686419f999b16515f08d71f504c23e88f901bb0b026c4f789e8aa058e2d61d1dc737efe960d9ea16c7306fae4bc768760ddd77ee96bd84072e4c1ba098eddff85e5ab2e4000351246c5643f4a7d9fc5b795d42a4fcc0778bd295838fa0ce0506dc3af77a1852ec4c487c7b9bff943e1d0ed549cdfe1f690fa206bc4be0a0a47a4551e448a223fd379c6b02fda0c82517b5849d90503974cb9cf05e96b9bda08ac4d24adc8b6e157ceab8fb71d3d38ed9ef426a607d4d6df240f6f5b39903a3a0e1721a33400b92fdc96813cea39fb55c3f0452b940e263c755cde4f33d2fddb4a01c08c64af0cb82544174d863c85dd0ff6bed0f189580d1403bc13cdbb8e65a2ea09912ae3ce11e78a8e9bbc22dabd85e73e724af0d48a17878ee58a98fef79c689a0d797eedf6cbb8744ff9c45caf9429a531fa9105b1dcd7acf8b972c57b5b10d24a099b4908a5c53640da0fe386c5eec74739172562c16fe942e3678cbb7f8ba3279a058edee54ed8bef1c85d44443c8f95bf7e0c79c7c98a64b0dae500ca393500f3880",
  "f901f1a09fefcbd8dadf63f3ffa900e12d51132aab12698a3d0765bb1e7411ebbe6eea92a007f4d0fce13b7655c4331798dbfa8fffda17396e874e84667195c34ef08a8e0ca009e3d3ce6c416f5d525cc029fc1bc2e242b1594bb114c957a16cafe69dba17c7a005070eae7ff699f036cb9f1a5c1658c6484a50a3cdbf9a1213e47f7fc563d1d4a055bfe5bbc3dfe1ab3219bd22f566883a679c5d9c1b64b7b940f5283bf1b7033680a053a08499bc933ae9615e4d33e9825ccc7930b1d3763ad2a6e5d17635059d9a41a0d56a238a2aace7e25abee78c1f30b35668a22fe7ed769d12abd3bf87e49315c1a05ae63d44ca78b0f41a55905e58303ebaa16b624410c6f7d4b1cca91296d49653a0679bfc4541d0fb9d95e8bc094154ef338d3a0ce6d8f97e7853d7d8813c1a9119a0c0ced8f2d7268fed3f0461c3f6195bf1d9b133de721087e22ec8d105270bc324a0690af7f7a977fc1ee9663526779eff76aa97a54561150e6fcb59b66d0da9de02a0ba3674e5ece4ac9843957c51acfef1e08eb7cf1f62c79f9386682007b436951aa0fe0c689b408385cda6e248f0ab0eaaff131cd63260aa8c55b9a612240e8530a5a0f53734da965d569a7240cb0bfb0db031963306bfac22faeab811f3d9b42b6deaa0d59e089b6b467ba7f1a0827282f302ffd6f2037130776a4ad1459986fb57589a80",
  "f8718080a03c1beafa55d56f1e109387c691ed50414fc70d65c537d6697bf440e2c89c686480808080808080a01feeeecbaf5bb240a280b12c627c07a5356ea7aa9701e91485da05abe87093a380808080a05a9af80f77fb6437495d51d966c86222c71e848f7d7961221bf92219e10e765280",
  "f8518080a00afcf4a2994fbc22fe7f03b4b96c5fa0f62f7bed7f408c39f9214943de3dd92a808080808080808080808080a0286f7ce7a20660e89e97c4e4a9391ceb92d8f9070ed9c3f5282009f98d28750280",
  "ea9d3012177e143ad19e9b933682593b94c1bfc0d41dec3fb8212230b495fc8b8a6319062efc0790b9d519",
];
let value = "6319062efc0790b9d519";
let valueEncoded = "8a6319062efc0790b9d519";

run(
  suite(
    "Verifier",
    [
      testLazy(
        "extractStorageValue",
        func() : Text {
          let _ = do ? {
            let _proof = Verifier.toStorageProof(storageHash, key, proof, null);
            let _value = Verifier.extractStorageValue(_proof!)!;
            return Value.toHex(_value)
          };
          "Failed to parse from text."
        },
        M.equals(T.text(valueEncoded)),
      ),
      testLazy(
        "verifyProof: true",
        func() : Bool {
          let _ = do ? {
            let _proof = Verifier.toStorageProof(storageHash, key, proof, ?value);
            return Verifier.verifyStorageProof(_proof!)
          };
          false
        },
        M.equals(T.bool(true)),
      ),
    ],
  )
)
