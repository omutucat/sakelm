import { Elm } from './Main.elm'
import './styles.css'

// Firebase設定
const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    databaseURL: import.meta.env.VITE_FIREBASE_DATABASE_URL,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
    measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID
};

// Firebase の初期化
firebase.initializeApp(firebaseConfig);

// Firebase認証関連の関数
function signInWithGoogle() {
    const provider = new firebase.auth.GoogleAuthProvider();
    return firebase.auth().signInWithPopup(provider);
}

function signOut() {
    return firebase.auth().signOut();
}

function getCurrentUser() {
    return firebase.auth().currentUser;
}

function onAuthStateChanged(callback) {
    return firebase.auth().onAuthStateChanged(callback);
}

// レビュー関連の関数
async function saveReviewToFirebase(reviewData) {
    const db = firebase.firestore();
    const storage = firebase.storage();

    try {
        // 現在のユーザー情報を取得
        const currentUser = getCurrentUser();
        if (!currentUser) {
            throw new Error('ユーザーがログインしていません');
        }

        // レビューデータの準備
        const timestamp = firebase.firestore.FieldValue.serverTimestamp();
        const reviewToSave = {
            userId: currentUser.uid,
            userName: currentUser.displayName || 'Anonymous',
            beverageId: reviewData.beverageId,
            beverageName: reviewData.beverageName,
            rating: reviewData.rating,
            title: reviewData.title,
            content: reviewData.content,
            imageUrl: null, // 初期値はnull
            likes: 0,
            createdAt: timestamp
        };

        // 画像がある場合はアップロード処理
        // ※実装は省略（ハリボテ）
        if (reviewData.imageFile) {
            // 実際はここでStorageにアップロード処理を行う
            reviewToSave.imageUrl = `https://via.placeholder.com/300/300?text=${encodeURIComponent(reviewData.title)}`;
        }

        // Firestoreにレビューを保存
        const reviewRef = await db.collection('reviews').add(reviewToSave);

        // 保存したデータにIDを付けて返す
        return {
            id: reviewRef.id,
            ...reviewToSave,
            createdAt: Date.now() // タイムスタンプをミリ秒に変換
        };

    } catch (error) {
        console.error('レビュー保存エラー:', error);
        throw error;
    }
}

// いいね機能（ハリボテ）
async function likeReview(reviewId) {
    // 実装は省略
    return { success: true };
}

// アプリ初期化
const app = Elm.Main.init({
    node: document.querySelector('main'),
    flags: {
        user: null // 初期状態ではユーザーはnull
    }
});

// Elm側からのリクエストを処理
app.ports.requestLogin.subscribe(() => {
    signInWithGoogle()
        .then(result => {
            const user = {
                uid: result.user.uid,
                displayName: result.user.displayName,
                email: result.user.email,
                photoURL: result.user.photoURL
            }
            app.ports.receiveUser.send(user)
        })
        .catch(error => {
            app.ports.receiveError.send({
                code: error.code,
                message: error.message
            })
        })
});

app.ports.requestLogout.subscribe(() => {
    signOut()
        .then(() => {
            app.ports.receiveUser.send(null)
        })
        .catch(error => {
            app.ports.receiveError.send({
                code: error.code,
                message: error.message
            })
        })
});

// レビュー保存リクエストの処理
app.ports.saveReview.subscribe((reviewData) => {
    const currentUser = getCurrentUser();

    if (!currentUser) {
        app.ports.receiveError.send({
            code: "auth-error",
            message: "レビューを投稿するにはログインしてください"
        });
        return;
    }

    // 画像ファイル処理はここでは省略（ハリボテ）
    // 実際にはアップロード処理などを行う

    saveReviewToFirebase(reviewData)
        .then((newReview) => {
            app.ports.reviewSaved.send({
                success: true,
                review: newReview
            });
        })
        .catch(error => {
            app.ports.receiveError.send({
                code: error.code || "unknown-error",
                message: error.message || "レビューの保存中にエラーが発生しました"
            });
            app.ports.reviewSaved.send({
                success: false
            });
        });
});

// Firebase認証状態の監視
onAuthStateChanged(user => {
    if (user) {
        app.ports.receiveUser.send({
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoURL: user.photoURL
        })
    } else {
        app.ports.receiveUser.send(null)
    }
});
