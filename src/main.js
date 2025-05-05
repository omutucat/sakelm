import { Elm } from './Main.elm'
import './styles.css'
// Firebase SDK V9 モジュールのインポート
import { initializeApp } from "firebase/app";
import {
    getAuth,
    GoogleAuthProvider,
    signInWithPopup,
    signOut as firebaseSignOut, // signOut が既に定義されているためエイリアスを使用
    onAuthStateChanged as firebaseOnAuthStateChanged, // onAuthStateChanged が既に定義されているためエイリアスを使用
} from "firebase/auth";
import {
    getFirestore,
    collection,
    addDoc,
    serverTimestamp,
    Timestamp // Timestamp をインポート
} from "firebase/firestore";
import {
    getStorage,
    ref as storageRef, // ref が他の変数と衝突する可能性があるためエイリアスを使用
    uploadBytes,
    getDownloadURL
} from "firebase/storage";


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
const firebaseApp = initializeApp(firebaseConfig);
const auth = getAuth(firebaseApp); // Auth インスタンスを取得
const db = getFirestore(firebaseApp); // Firestore インスタンスを取得
const storage = getStorage(firebaseApp); // Storage インスタンスを取得

// Firebase認証関連の関数
function signInWithGoogle() {
    const provider = new GoogleAuthProvider();
    return signInWithPopup(auth, provider); // auth インスタンスを渡す
}

function signOut() {
    return firebaseSignOut(auth); // auth インスタンスを渡す
}

function getCurrentUser() {
    return auth.currentUser; // auth インスタンスの currentUser プロパティを使用
}

function onAuthStateChanged(callback) {
    return firebaseOnAuthStateChanged(auth, callback); // auth インスタンスを渡す
}

// レビュー関連の関数
async function saveReviewToFirebase(reviewData) {
    // db と storage はグローバルスコープで初期化済み

    try {
        // 現在のユーザー情報を取得
        const currentUser = getCurrentUser();
        if (!currentUser) {
            throw new Error('ユーザーがログインしていません');
        }

        // レビューデータの準備
        const timestamp = serverTimestamp(); // Firestore のサーバータイムスタンプ
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
            createdAt: timestamp // Firestore の Timestamp オブジェクト
        };

        // 画像がある場合はアップロード処理
        // ※実装は省略（ハリボテ）
        if (reviewData.imageFile) {
            // 実際はここでStorageにアップロード処理を行う
            // 例: const imageRef = storageRef(storage, `reviews/${currentUser.uid}/${Date.now()}_${reviewData.imageFile.name}`);
            // await uploadBytes(imageRef, reviewData.imageFile);
            // reviewToSave.imageUrl = await getDownloadURL(imageRef);
            reviewToSave.imageUrl = `https://via.placeholder.com/300/300?text=${encodeURIComponent(reviewData.title)}`;
        }

        // Firestoreにレビューを保存
        const reviewsCollection = collection(db, 'reviews'); // コレクション参照を取得
        const reviewRef = await addDoc(reviewsCollection, reviewToSave); // ドキュメントを追加

        // 保存したデータにIDを付けて返す
        // createdAt はサーバーで設定されるため、クライアント側で Date.now() を使う代わりに null または推定値を返す
        // Elm側で Timestamp を扱えない場合は、ここでミリ秒に変換する必要があるかもしれない
        return {
            id: reviewRef.id,
            ...reviewToSave,
            // Firestore の Timestamp はオブジェクト。Elm に渡す前に変換が必要な場合がある
            // 例: createdAt: Date.now() // または null のままにする
            createdAt: Date.now() // ハリボテとして現在の時刻を設定
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
