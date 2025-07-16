//
//  AIBreakdownService.swift
//  To-Do List
//
//  Created by Khai Nguyen on 14/7/25.
//

import Foundation

class AIBreakdownService {
    static let shared = AIBreakdownService()
    private let apiKey = "JkyB73VaUIrv0mCYngsciONeUGYwq81NtoKGe79t" // Thay bằng Cohere API key của bạn

    func breakdownTask(taskName: String, completion: @escaping ([String]?) -> Void) {
        let prompt = "List only the small steps to complete the task: \(taskName). Each step should be a single short sentence. Do not include any introduction, summary, bullet points, dashes, numbers, or any special characters at the beginning of each line. Only output the steps, each on a new line."
        let url = URL(string: "https://api.cohere.ai/v1/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "command", // hoặc "command-light" nếu quota thấp
            "prompt": prompt,
            "max_tokens": 200,
            "temperature": 0.7,
            "k": 0,
            "stop_sequences": ["--"]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error Network: \(error)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("No Data")
                completion(nil)
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let generations = json["generations"] as? [[String: Any]],
               let text = generations.first?["text"] as? String {
                let subtasks = text
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                DispatchQueue.main.async {
                    completion(subtasks)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        task.resume()
    }
}
