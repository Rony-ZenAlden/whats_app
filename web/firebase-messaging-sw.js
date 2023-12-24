importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-messaging.js');


  const firebaseConfig = {
          apiKey: 'AIzaSyDqLPYIeEg9QRQ5-nHP8bQZfPUVFQ_SVGQ',
          appId: '1:563129663089:web:b4cbe26dbe52b04e5b25d0',
          messagingSenderId: '563129663089',
          projectId: 'whatsapp-f6fc8',
          authDomain: 'whatsapp-f6fc8.firebaseapp.com',
          storageBucket: 'whatsapp-f6fc8.appspot.com',
          measurementId: 'G-H6V7XE86M1',
    };
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();


  messaging.onBackgroundMessage(function(payload) {
    console.log('Received background message ', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
      body: payload.notification.body,
    };

    self.registration.showNotification(notificationTitle,
      notificationOptions);
  });