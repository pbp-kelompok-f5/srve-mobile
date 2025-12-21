// Timpa seluruh isi file dengan ini, atau tambahkan field isHost
import 'dart:convert';

List<Match> matchFromJson(String str) => List<Match>.from(json.decode(str).map((x) => Match.fromJson(x)));

String matchToJson(List<Match> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Match {
    String model;
    int pk;
    Fields fields;

    Match({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory Match.fromJson(Map<String, dynamic> json) => Match(
        model: json["model"],
        pk: json["pk"],
        fields: Fields.fromJson(json["fields"]),
    );

    Map<String, dynamic> toJson() => {
        "model": model,
        "pk": pk,
        "fields": fields.toJson(),
    };
}

class Fields {
    int host;
    String title;
    DateTime tanggal;
    String lokasi;
    bool isCompleted;
    DateTime createdAt;
    String jenisOlahraga;
    int maxPlayers;
    List<int> players;
    bool isHost; // TAMBAHAN FIELD BARU

    Fields({
        required this.host,
        required this.title,
        required this.tanggal,
        required this.lokasi,
        required this.isCompleted,
        required this.createdAt,
        required this.jenisOlahraga,
        required this.maxPlayers,
        required this.players,
        required this.isHost, // TAMBAHAN
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        host: json["host"],
        title: json["title"] ?? "Untitled Match",
        tanggal: json["tanggal"] != null ? DateTime.parse(json["tanggal"]) : DateTime.now(),
        lokasi: json["lokasi"],
        isCompleted: json["is_completed"] ?? false,
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
        jenisOlahraga: json["jenis_olahraga"],
        maxPlayers: json["max_players"],
        players: List<int>.from(json["players"].map((x) => x)),
        isHost: json["is_host"] ?? false, // BACA DARI JSON, DEFAULT FALSE
    );

    Map<String, dynamic> toJson() => {
        "host": host,
        "title": title,
        "tanggal": "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
        "lokasi": lokasi,
        "is_completed": isCompleted,
        "created_at": createdAt.toIso8601String(),
        "jenis_olahraga": jenisOlahraga,
        "max_players": maxPlayers,
        "players": List<dynamic>.from(players.map((x) => x)),
        "is_host": isHost,
    };
}