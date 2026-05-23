<%@ page import="java.util.*, java.io.*, java.nio.file.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    request.setCharacterEncoding("UTF-8");
    String dataDir = application.getRealPath("/WEB-INF/data");
    File dir = new File(dataDir);
    if (!dir.exists()) dir.mkdirs();

    String title = request.getParameter("title");
    String name  = request.getParameter("name");
    String body  = request.getParameter("body");

    String message = null;
    if (title != null && body != null) {
        if (title.trim().isEmpty() || body.trim().isEmpty()) {
            message = "タイトルと本文は必須です。";
        } else {
            String id = UUID.randomUUID().toString().substring(0, 8);
            File f = new File(dir, id + ".txt");
            try (PrintWriter pw = new PrintWriter(new OutputStreamWriter(new FileOutputStream(f), "UTF-8"))) {
                pw.println(title.trim());
                pw.println(name != null && !name.trim().isEmpty() ? name.trim() : "名無し");
                pw.println(body.trim());
                pw.println(System.currentTimeMillis());
            }
            response.sendRedirect("thread.jsp?id=" + id);
            return;
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Compeitou BBS - 新規スレッド</title>
    <style>
        body { background: #F0F0F0; font-family: serif; }
        table { width: 80%; margin: auto; border-collapse: collapse; background: #FFF; }
        th, td { padding: 8px; border: 1px solid #CCC; }
        th { background: #CCCCCC; }
        .title { font-size: 24px; font-weight: bold; text-align: center; padding: 10px; background: #CCCCCC; }
        .nav { text-align: right; padding: 5px; background: #EEEEEE; }
        .footer { text-align: center; font-size: small; padding: 10px; }
        input, textarea { width: 100%; box-sizing: border-box; }
        .error { color: red; }
    </style>
</head>
<body>
<table>
    <tr><td class="title">新規スレッド作成</td></tr>
    <tr><td class="nav"><a href="index.jsp">スレッド一覧に戻る</a></td></tr>
</table>
<br>
<table>
    <% if (message != null) { %>
    <tr><td class="error"><%= message %></td></tr>
    <% } %>
    <form method="post">
    <tr><th>タイトル</th></tr>
    <tr><td><input type="text" name="title" required></td></tr>
    <tr><th>名前 (省略可)</th></tr>
    <tr><td><input type="text" name="name" value="名無し"></td></tr>
    <tr><th>本文</th></tr>
    <tr><td><textarea name="body" rows="6" required></textarea></td></tr>
    <tr><td style="text-align:center;"><input type="submit" value="スレッドを立てる" style="width:auto;"></td></tr>
    </form>
</table>
<br>
<table><tr><td class="footer">&copy; 2026 Compeitou. All Rights Reserved.</td></tr></table>
</body>
</html>
