// seed_emoticons.js
// Firestore에 이모티콘 테스트팩 데이터를 넣는 1회성 스크립트입니다.
// 실행: node seed_emoticons.js
//
// 사전 준비:
// 1. Firebase 콘솔 > 프로젝트 설정 > 서비스 계정 > "새 비공개 키 생성" 으로
//    serviceAccountKey.json 파일을 받아서 이 스크립트와 같은 폴더에 둡니다.
// 2. npm install firebase-admin

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const characterFiles = [
  '01_smile.svg', '02_bigsmile.svg', '03_sad.svg', '04_crying.svg',
  '05_angry.svg', '06_surprised.svg', '07_love.svg', '08_wink.svg',
  '09_shy.svg', '10_sleepy.svg', '11_dizzy.svg', '12_cool.svg',
  '13_worried.svg', '14_blank.svg', '15_clap.svg', '16_victory.svg',
  '17_thanks.svg', '18_fighting.svg', '19_hurt.svg', '20_curious.svg',
];

const emojiFiles = characterFiles; // 파일명 동일, 폴더만 다름
const memeFiles = characterFiles;

function buildItems(folder, files) {
  return files.map((f) => ({
    itemId: f,
    imageUrl: `assets/emoticons/${folder}/${f}`,
  }));
}

async function seed() {
  const packs = [
    {
      id: 'emo_character_test',
      name: '이모티콘 테스트팩 (캐릭터형)',
      imageUrl: 'assets/emoticons/character/01_smile.svg',
      pricePoint: 500,
      isActive: true,
      items: buildItems('character', characterFiles),
    },
    {
      id: 'emo_emoji_test',
      name: '이모티콘 테스트팩 (이모지형)',
      imageUrl: 'assets/emoticons/emoji/01_smile.svg',
      pricePoint: 500,
      isActive: true,
      items: buildItems('emoji', emojiFiles),
    },
    {
      id: 'emo_meme_test',
      name: '이모티콘 테스트팩 (밈/리액션형)',
      imageUrl: 'assets/emoticons/meme/01_smile.svg',
      pricePoint: 500,
      isActive: true,
      items: buildItems('meme', memeFiles),
    },
  ];

  for (const pack of packs) {
    const { id, ...data } = pack;
    await db.collection('emoticon').doc(id).set(data);
    console.log(`등록 완료: ${id}`);
  }

  console.log('전체 완료');
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
