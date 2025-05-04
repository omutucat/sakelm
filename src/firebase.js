// Firebase認証関連の関数

export function signInWithGoogle() {
    const provider = new firebase.auth.GoogleAuthProvider();
    return firebase.auth().signInWithPopup(provider);
}

export function signOut() {
    return firebase.auth().signOut();
}

export function getCurrentUser() {
    return firebase.auth().currentUser;
}

export function onAuthStateChanged(callback) {
    return firebase.auth().onAuthStateChanged(callback);
}

// レビュー関連の関数
export async function saveReviewToFirebase(reviewData) {
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
export async function likeReview(reviewId) {
    // 実装は省略
    return { success: true };
}
