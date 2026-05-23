<%@ page import="java.util.*, java.io.*, java.nio.file.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String dataDir = application.getRealPath("/WEB-INF/data");
    File dir = new File(dataDir);
    if (!dir.exists()) dir.mkdirs();

    List<Map<String,String>> threads = new ArrayList<>();
    File[] files = dir.listFiles((d, name) -> name.endsWith(".txt"));
    if (files != null) {
        Arrays.sort(files, (a, b) -> Long.compare(b.lastModified(), a.lastModified()));
        for (File f : files) {
            Map<String,String> t = new LinkedHashMap<>();
            t.put("id", f.getName().replace(".txt", ""));
            List<String> lines = Files.readAllLines(f.toPath());
            if (!lines.isEmpty()) t.put("title", lines.get(0));
            t.put("posts", String.valueOf(lines.size() / 4));
            threads.add(t);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Compeitou BBS - スレッド一覧</title>
    <style>
        body { background: #F0F0F0; font-family: serif; }
        table { width: 80%; margin: auto; border-collapse: collapse; background: #FFF; }
        th, td { padding: 8px; border: 1px solid #CCC; text-align: left; }
        th { background: #CCCCCC; }
        .title { font-size: 24px; font-weight: bold; text-align: center; padding: 10px; background: #CCCCCC; }
        .nav { text-align: right; padding: 5px; background: #EEEEEE; }
        .footer { text-align: center; font-size: small; color: #000; padding: 10px; }
    </style>
</head>
<body>
<table>
    <tr><td class="title">Compeitou BBS</td></tr>
    <tr><td class="nav"><a href="post.jsp">新規スレッドを立てる</a></td></tr>
</table>
<br>
<table>
    <tr><th>スレッドタイトル</th><th>投稿数</th><th>最終更新</th></tr>
    <% if (threads.isEmpty()) { %>
    <tr><td colspan="3" style="text-align:center; color:#888;">スレッドがありません。</td></tr>
    <% } else {
        for (Map<String,String> t : threads) { %>
    <tr>
        <td><a href="thread.jsp?id=<%= t.get("id") %>"><%= t.get("title") %></a></td>
        <td><%= t.get("posts") %></td>
        <td><%= new java.util.Date(new File(dir, t.get("id") + ".txt").lastModified()) %></td>
    </tr>
    <%  }
    } %>
</table>
<br>
<table><tr><td class="footer">&copy; 2026 Compeitou. All Rights Reserved.</td></tr></table>
</body>
</html>
