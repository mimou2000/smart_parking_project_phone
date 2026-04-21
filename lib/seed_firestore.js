// seed_firestore.js
// شغّله مرة واحدة من Firebase Console → Functions أو باستخدام Node.js
// node seed_firestore.js

const { initializeApp } = require('firebase/app');
const { getFirestore, collection, doc, setDoc, writeBatch } = require('firebase/firestore');

const firebaseConfig = {
  apiKey:            "AIzaSyAMiyQTVzxI8pisDXbxCwgfH6mZsybzKOA",
  authDomain:        "smartparking-realtime.firebaseapp.com",
  projectId:         "smartparking-realtime",
  storageBucket:     "smartparking-realtime.firebasestorage.app",
  messagingSenderId: "944561185785",
  appId:             "1:944561185785:web:6afbd401903479cc27d328",
};

const app = initializeApp(firebaseConfig);
const db  = getFirestore(app);

const zones = [
  {
    id: 'z1',
    name: 'موقف الواجهة البحرية',
    address: 'شارع الاستقلال، سطيف',
    lat: 36.1901, lng: 5.4108,
    totalSpots: 20, availableSpots: 12,
    pricePerHour: 50, distance: 0.3,
  },
  {
    id: 'z2',
    name: 'موقف المركز التجاري',
    address: 'حي 8 ماي 1945، سطيف',
    lat: 36.1880, lng: 5.4130,
    totalSpots: 20, availableSpots: 0,
    pricePerHour: 80, distance: 0.7,
  },
  {
    id: 'z3',
    name: 'موقف المستشفى',
    address: 'طريق قسنطينة، سطيف',
    lat: 36.1860, lng: 5.4080,
    totalSpots: 16, availableSpots: 5,
    pricePerHour: 40, distance: 1.2,
  },
  {
    id: 'z4',
    name: 'موقف الجامعة',
    address: 'جامعة فرحات عباس، سطيف',
    lat: 36.1920, lng: 5.4160,
    totalSpots: 24, availableSpots: 14,
    pricePerHour: 30, distance: 1.8,
  },
];

async function seed() {
  console.log('⏳ جاري البذر...');
  for (const zone of zones) {
    const { id, ...data } = zone;
    const zoneRef = doc(db, 'parkingZones', id);
    await setDoc(zoneRef, data);
    console.log(`✅ منطقة: ${data.name}`);

    // إنشاء المواقف الصغيرة
    const batch = writeBatch(db);
    for (let i = 1; i <= data.totalSpots; i++) {
      const spotRef = doc(collection(zoneRef, 'spots'));
      batch.set(spotRef, {
        number:  i,
        isTaken: i > data.availableSpots,
      });
    }
    await batch.commit();
    console.log(`   └─ ${data.totalSpots} موقف صغير`);
  }
  console.log('\n🎉 اكتمل البذر بنجاح!');
  process.exit(0);
}

seed().catch(e => { console.error(e); process.exit(1); });
