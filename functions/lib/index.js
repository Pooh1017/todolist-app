"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const admin = __importStar(require("firebase-admin"));
(0, v2_1.setGlobalOptions)({ region: "asia-southeast1" });
// ✅ ให้เห็น error ที่หลุด try/catch
process.on("unhandledRejection", (e) => console.error("UNHANDLED REJECTION:", e));
process.on("uncaughtException", (e) => console.error("UNCAUGHT EXCEPTION:", e));
// ✅ init admin
if (!admin.apps.length)
    admin.initializeApp();
const getDb = () => admin.firestore();
// =====================
// Express app
// =====================
const app = (0, express_1.default)();
app.disable("x-powered-by");
app.set("trust proxy", true);
// ✅ Request log
app.use((req, _res, next) => {
    console.log("REQ", req.method, req.originalUrl, "CT=", req.headers["content-type"]);
    next();
});
// ✅ CORS
const corsMw = (0, cors_1.default)({
    origin: true,
    methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    maxAge: 86400,
});
// ✅ preflight
app.options("*", corsMw);
app.use(corsMw);
// ✅ parse body
app.use(express_1.default.json({ limit: "1mb" }));
app.use(express_1.default.urlencoded({ extended: true }));
// ✅ JSON parse error handler
app.use((err, _req, res, next) => {
    if (!err)
        return next();
    console.error("BODY PARSE ERROR:", err);
    return res.status(400).json({ ok: false, error: "invalid json" });
});
// ---------- utils ----------
const s = (v) => (v == null ? "" : String(v).trim());
const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
const getBearer = (req) => {
    const h = s(req.header("authorization"));
    const m = h.match(/^Bearer\s+(.+)$/i);
    return m ? s(m[1]) : "";
};
const boolOrUndef = (v) => {
    if (v === undefined)
        return undefined;
    if (typeof v === "boolean")
        return v;
    if (typeof v === "string") {
        const t = v.trim().toLowerCase();
        if (t === "true")
            return true;
        if (t === "false")
            return false;
    }
    return undefined;
};
function fail(res, code, error) {
    return res.status(code).json({ ok: false, error });
}
// =====================
// AUTH MIDDLEWARE
// =====================
async function requireAuth(req, res, next) {
    try {
        const token = getBearer(req);
        if (!token)
            return fail(res, 401, "missing token");
        if (token === "demo-token") {
            req.user = { uid: "demo-user" };
            return next();
        }
        const decoded = await admin.auth().verifyIdToken(token);
        req.user = decoded;
        return next();
    }
    catch (e) {
        console.error("AUTH ERROR:", e);
        return fail(res, 401, "invalid token");
    }
}
// =====================
// API ROUTER (ทุกอย่างอยู่ใต้ /api)
// =====================
const apiRouter = express_1.default.Router();
// ✅ debug => /api/__debug
apiRouter.all("/__debug", (req, res) => {
    return res.json({
        ok: true,
        method: req.method,
        originalUrl: req.originalUrl,
        path: req.path,
        baseUrl: req.baseUrl,
        headers: req.headers,
        body: req.body,
    });
});
// ✅ ping => /api/ping
apiRouter.get("/ping", (_req, res) => res.json({ ok: true, ping: "pong" }));
// ---------- LOGIN ----------
// /api/auth/login
apiRouter.post("/auth/login", (req, res) => {
    try {
        console.log("LOGIN BODY =", req.body);
        const body = req.body;
        if (!body || typeof body !== "object")
            return fail(res, 400, "invalid body");
        const email = s(body.email).toLowerCase();
        const password = s(body.password);
        if (!email || !password)
            return fail(res, 400, "email/password required");
        if (!isValidEmail(email))
            return fail(res, 400, "invalid email");
        if (password.length < 6)
            return fail(res, 400, "invalid password");
        if (email === "test@mail.com" && password === "123456") {
            return res.status(200).json({ ok: true, token: "demo-token", email });
        }
        return fail(res, 401, "invalid credentials");
    }
    catch (e) {
        console.error("LOGIN ERROR:", e);
        return fail(res, 500, "server error");
    }
});
// ======================================================
// TASKS  => /api/tasks...
// ======================================================
apiRouter.get("/tasks", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const snap = await db
            .collection("users")
            .doc(uid)
            .collection("tasks")
            .orderBy("createdAt", "desc")
            .get();
        return res.json({
            ok: true,
            data: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
        });
    }
    catch (e) {
        console.error("GET /tasks ERROR:", e);
        return fail(res, 500, "server error");
    }
});
apiRouter.post("/tasks", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const title = s(req.body?.title);
        const categoryId = s(req.body?.categoryId);
        const date = s(req.body?.date);
        const note = s(req.body?.note);
        if (!title || !date)
            return fail(res, 400, "title/date required");
        const done = boolOrUndef(req.body?.done);
        const starred = boolOrUndef(req.body?.starred);
        if (req.body?.done !== undefined && done === undefined)
            return fail(res, 400, "invalid done");
        if (req.body?.starred !== undefined && starred === undefined)
            return fail(res, 400, "invalid starred");
        const now = Date.now();
        const doc = await db.collection("users").doc(uid).collection("tasks").add({
            title,
            categoryId: categoryId || "",
            date,
            note: note || "",
            done: done ?? false,
            starred: starred ?? false,
            deleted: false,
            createdAt: now,
            updatedAt: now,
        });
        return res.status(201).json({ ok: true, id: doc.id });
    }
    catch (e) {
        console.error("POST /tasks ERROR:", e);
        return fail(res, 500, "server error");
    }
});
apiRouter.get("/tasks/:id", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const id = s(req.params?.id);
        if (!id)
            return fail(res, 400, "id required");
        const ref = db.collection("users").doc(uid).collection("tasks").doc(id);
        const doc = await ref.get();
        if (!doc.exists)
            return fail(res, 404, "not found");
        return res.json({ ok: true, data: { id: doc.id, ...doc.data() } });
    }
    catch (e) {
        console.error("GET /tasks/:id ERROR:", e);
        return fail(res, 500, "server error");
    }
});
apiRouter.patch("/tasks/:id", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const id = s(req.params?.id);
        if (!id)
            return fail(res, 400, "id required");
        const ref = db.collection("users").doc(uid).collection("tasks").doc(id);
        const doc = await ref.get();
        if (!doc.exists)
            return fail(res, 404, "not found");
        const patch = {};
        if (req.body?.title !== undefined)
            patch.title = s(req.body.title);
        if (req.body?.categoryId !== undefined)
            patch.categoryId = s(req.body.categoryId);
        if (req.body?.date !== undefined)
            patch.date = s(req.body.date);
        if (req.body?.note !== undefined)
            patch.note = s(req.body.note);
        const done = boolOrUndef(req.body?.done);
        const starred = boolOrUndef(req.body?.starred);
        if (req.body?.done !== undefined && done === undefined)
            return fail(res, 400, "invalid done");
        if (req.body?.starred !== undefined && starred === undefined)
            return fail(res, 400, "invalid starred");
        if (done !== undefined)
            patch.done = done;
        if (starred !== undefined)
            patch.starred = starred;
        if (patch.title !== undefined && !patch.title)
            return fail(res, 400, "title required");
        if (patch.date !== undefined && !patch.date)
            return fail(res, 400, "date required");
        if (Object.keys(patch).length === 0)
            return fail(res, 400, "empty patch");
        patch.updatedAt = Date.now();
        await ref.update(patch);
        return res.json({ ok: true });
    }
    catch (e) {
        console.error("PATCH /tasks/:id ERROR:", e);
        return fail(res, 500, "server error");
    }
});
apiRouter.delete("/tasks/:id", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const id = s(req.params?.id);
        if (!id)
            return fail(res, 400, "id required");
        const ref = db.collection("users").doc(uid).collection("tasks").doc(id);
        const doc = await ref.get();
        if (!doc.exists)
            return fail(res, 404, "not found");
        await ref.update({ deleted: true, updatedAt: Date.now() });
        return res.json({ ok: true });
    }
    catch (e) {
        console.error("DELETE /tasks/:id ERROR:", e);
        return fail(res, 500, "server error");
    }
});
// ======================================================
// CATEGORIES => /api/categories...
// ======================================================
apiRouter.get("/categories", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const snap = await db
            .collection("users")
            .doc(uid)
            .collection("categories")
            .orderBy("createdAt", "desc")
            .get();
        return res.json({
            ok: true,
            data: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
        });
    }
    catch (e) {
        console.error("GET /categories ERROR:", e);
        return fail(res, 500, "server error");
    }
});
apiRouter.post("/categories", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const name = s(req.body?.name);
        if (!name)
            return fail(res, 400, "name required");
        const doc = await db.collection("users").doc(uid).collection("categories").add({
            name,
            createdAt: Date.now(),
        });
        return res.status(201).json({ ok: true, id: doc.id });
    }
    catch (e) {
        console.error("POST /categories ERROR:", e);
        return fail(res, 500, "server error");
    }
});
apiRouter.delete("/categories/:id", requireAuth, async (req, res) => {
    try {
        const uid = req.user.uid;
        const db = getDb();
        const id = s(req.params?.id);
        if (!id)
            return fail(res, 400, "id required");
        const ref = db.collection("users").doc(uid).collection("categories").doc(id);
        const doc = await ref.get();
        if (!doc.exists)
            return fail(res, 404, "not found");
        await ref.delete();
        return res.json({ ok: true });
    }
    catch (e) {
        console.error("DELETE /categories/:id ERROR:", e);
        return fail(res, 500, "server error");
    }
});
// ✅ mount router: ทุกอย่างจะกลายเป็น /api/...
app.use("/api", apiRouter);
// ✅ Global error handler
app.use((err, _req, res, _next) => {
    console.error("UNHANDLED ERROR:", err);
    return res.status(500).json({ ok: false, error: "internal error" });
});
// ✅ 404
app.use((_req, res) => {
    return res.status(404).json({ ok: false, error: "not found" });
});
// ✅ Functions v2 — export ต้องชื่อ api ให้ตรงกับ firebase.json
exports.api = (0, https_1.onRequest)({ region: "asia-southeast1", timeoutSeconds: 120, memory: "512MiB" }, app);
//# sourceMappingURL=index.js.map