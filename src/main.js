import { Elm } from './Main.elm'
import './styles.css'
import { signInWithGoogle, signOut, onAuthStateChanged, getCurrentUser, saveReviewToFirebase } from './firebase.js'
import { firebaseConfig } from './config.js'

// Firebase の初期化
firebase.initializeApp(firebaseConfig)

// アプリ初期化
const app = Elm.Main.init({
    node: document.querySelector('main'),
    flags: {
        user: null // 初期状態ではユーザーはnull
    }
})

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
})

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
})

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
})

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
})
