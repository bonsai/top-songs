<%@ page import="java.util.*, java.io.*, java.nio.file.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    request.setCharacterEncoding("UTF-8");
    String dataDir = application.getRealPath("/WEB-INF/data");
    File dir = new File(dataDir);
    if (!dir.exists()) dir.mkdirs();

    String id = request.getParameter("id");
    if (id == null || id.isEmpty()) {
        response.sendRedirect("index.jsp");
        return;
    }

    // 返信処理
    String replyName = request.getParameter("reply_name");
    String replyBody = request.getParameter("reply_body");
    if (replyBody != null && !replyBody.trim().isEmpty()) {
        File f = new File(dir, id + ".txt");
        try (FileWriter fw = new FileWriter(f, true)) {
            fw.write("\n");
            fw.write((replyName != null && !replyName.trim().isEmpty() ? replyName.trim() : "名無し") + "\n");
            fw.write(replyBody.trim() + "\n");
            fw.write(System.currentTimeMillis() + "\n");
        }
        response.sendRedirect("thread.jsp?id=" + id);
        return;
    }

    File f = new File(dir, id + ".txt");
    if (!f.exists()) {
        response.sendRedirect("index.jsp");
        return;
    }

    List<String> lines = Files.readAllLines(f.toPath());
    String threadTitle = lines.isEmpty() ? "不明" : lines.get(0);

    List<Map<String,String>> posts = new ArrayList<>();
    for (int i = 0; i + 3 <= lines.size(); i += 4) {
        Map<String,String> p = new LinkedHashMap<>();
        p.put("name", lines.get(i + 1));
        p.put("body", lines.get(i + 2));
        long ts = Long.parseLong(lines.get(i + 3));
        p.put("date", new java.text.SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(new java.util.Date(ts)));
        posts.add(p);
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Compeitou BBS - <%= threadTitle %></title>
    <style>
        body { background: #F0F0F0; font-family: serif; }
        table { width: 80%; margin: auto; border-collapse: collapse; background: #FFF; }
        th, td { padding: 8px; border: 1px solid #CCC; }
        th { background: #CCCCCC; }
        .title { font-size: 24px; font-weight: bold; text-align: center; padding: 10px; background: #CCCCCC; }
        .nav { text-align: right; padding: 5px; background: #EEEEEE; }
        .footer { text-align: center; font-size: small; padding: 10px; }
        .post-name { font-weight: bold; color: #008000; }
        .post-date { font-size: small; color: #888; }
        .post-body { padding: 10px 0; white-space: pre-wrap; }
        input, textarea { width: 100%; box-sizing: border-box; }
    </style>
</head>
<body>
<table>
    <tr><td class="title"><%= threadTitle %></td></tr>
    <tr><td class="nav"><a href="index.jsp">スレッド一覧に戻る</a></td></tr>
</table>
<br>
<table>
    <% for (int i = 0; i < posts.size(); i++) {
        Map<String,String> p = posts.get(i); %>
    <tr><td>
        <span class="post-name"><%= p.get("name") %></span>
        <span class="post-date"><%= p.get("date") %> No.<%= i + 1 %></span>
        <div class="post-body"><%= p.get("body") %></div>
    </td></tr>
    <% } %>
</table>
<br>
<table>
    <tr><th>返信する</th></tr>
    <form method="post">
    <tr><td>名前: <input type="text" name="reply_name" value="名無し" style="width:200px;"></td></tr>
    <tr><td><textarea name="reply_body" rows="4" required></textarea></td></tr>
    <tr><td style="text-align:center;"><input type="submit" value="書き込む" style="width:auto;"></td></tr>
    </form>
</table>
<br>
<table><tr><td class="footer">&copy; 2026 Compeitou. All Rights Reserved.</td></tr></table>
</body>
</html>
