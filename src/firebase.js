// Firebase SDK v9の互換モードを使用して認証機能を実装します
const auth = firebase.auth;

// Google認証プロバイダーの設定
const googleProvider = new auth.GoogleAuthProvider();
googleProvider.setCustomParameters({ prompt: 'select_account' });

// Googleでサインイン
export const signInWithGoogle = () => {
    return auth().signInWithPopup(googleProvider);
};

// サインアウト
export const signOut = () => {
    return auth().signOut();
};

// 認証状態の変更を監視するための関数
export const onAuthStateChanged = (callback) => {
    return auth().onAuthStateChanged(callback);
};

// 現在のユーザー情報を取得
export const getCurrentUser = () => {
    return auth().currentUser;
};
