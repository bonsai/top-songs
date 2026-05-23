// Firebase configuration (Replace with your project's actual config)
const firebaseConfig = {
    apiKey: "AIzaSyDYlU9ya8_GmI4_hYNFEkB-PvTUZHco044",
    authDomain: "gen-lang-client-0315818888.firebaseapp.com",
    projectId: "gen-lang-client-0315818888",
    databaseURL: "https://gen-lang-client-0315818888-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "gen-lang-client-0315818888.firebasestorage.app",
    messagingSenderId: "826943922547",
    appId: "1:826943922547:web:c41cb04a07da9262672506"
};

// Initialize Firebase
const app = firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const database = firebase.database();

// --- Utility Functions ---
function getQueryParams() {
    const params = {};
    window.location.search.substring(1).split('&').forEach(param => {
        const parts = param.split('=');
        params[parts[0]] = decodeURIComponent(parts[1]);
    });
    return params;
}

function formatDate(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString();
}

function escapeHTML(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
}

// --- Auth Logic ---
let currentUser = null;

auth.onAuthStateChanged(user => {
    currentUser = user;
    console.log("Auth state changed: ", user ? user.email : "Logged out");
    // Update UI based on auth state (e.g., hide/show login/logout links)
    if (document.getElementById('login-signup-link')) {
        if (user) {
            document.getElementById('login-signup-link').innerHTML = `<font color="#0000FF">ログアウト (${escapeHTML(user.email)})</font>`;
            document.getElementById('login-signup-link').href = "#logout";
            document.getElementById('login-signup-link').onclick = handleLogout;
        } else {
            document.getElementById('login-signup-link').innerHTML = `<font color="#0000FF">ログイン / サインアップ</font>`;
            document.getElementById('login-signup-link').href = "./auth.html";
            document.getElementById('login-signup-link').onclick = null;
        }
    }
    // If on auth.html, redirect to index if logged in
    if (window.location.pathname.endsWith('/auth.html') && user) {
        window.location.href = './index.html';
    }

    // Call page-specific initialization if available
    if (window.onPageLoad) {
        window.onPageLoad();
    }
});

function handleSignup(event) {
    event.preventDefault();
    const email = document.getElementById('signup-email').value;
    const password = document.getElementById('signup-password').value;
    auth.createUserWithEmailAndPassword(email, password)
        .then(userCredential => {
            alert('サインアップ成功！');
        })
        .catch(error => {
            alert('サインアップ失敗: ' + error.message);
            console.error(error);
        });
}

function handleLogin(event) {
    event.preventDefault();
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    auth.signInWithEmailAndPassword(email, password)
        .then(userCredential => {
            alert('ログイン成功！');
        })
        .catch(error => {
            alert('ログイン失敗: ' + error.message);
            console.error(error);
        });
}

function handleLogout(event) {
    event.preventDefault();
    auth.signOut()
        .then(() => {
            alert('ログアウトしました。');
            window.location.href = './index.html';
        })
        .catch(error => {
            alert('ログアウト失敗: ' + error.message);
            console.error(error);
        });
}

function handleResetPassword(event) {
    event.preventDefault();
    const email = prompt('パスワードをリセットするメールアドレスを入力してください:');
    if (email) {
        auth.sendPasswordResetEmail(email)
            .then(() => {
                alert('パスワードリセットのメールを送信しました。');
            })
            .catch(error => {
                alert('パスワードリセット失敗: ' + error.message);
                console.error(error);
            });
    }
}

// --- Page-specific Event Listeners ---
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('signup-form')) {
        document.getElementById('signup-form').addEventListener('submit', handleSignup);
    }
    if (document.getElementById('login-form')) {
        document.getElementById('login-form').addEventListener('submit', handleLogin);
    }
    if (document.getElementById('reset-password-link')) {
        document.getElementById('reset-password-link').addEventListener('click', handleResetPassword);
    }
    // Ensure login/signup link on index.html updates
    const loginSignupLink = document.querySelector('a[href="./auth.html"]');
    if (loginSignupLink) {
        loginSignupLink.id = 'login-signup-link';
    }

    // For pages other than auth.html, ensure login/signup link text is correct on initial load
    if (!window.location.pathname.endsWith('/auth.html')) {
        // Trigger onAuthStateChanged manually if user is already logged in and it didn't fire immediately
        if (auth.currentUser) {
            auth.onAuthStateChanged(auth.currentUser); // Re-trigger to update UI
        }
    }
});