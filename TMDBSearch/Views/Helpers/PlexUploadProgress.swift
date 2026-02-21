//
//  PlexUploadProgress.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import SwiftUI

// MARK: - Plex Upload Progress View

struct PlexUploadProgress: View {
    let mediaTitle: String
    @Binding var tasks: [AssetUploadTask]
    @Binding var currentTaskIndex: Int
    @Binding var isPresented: Bool
    let onCancel: () -> Void
    
    private var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    private var failedCount: Int {
        tasks.filter { $0.status == .failed }.count
    }
    
    private var totalCount: Int {
        tasks.count
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount + failedCount) / Double(totalCount)
    }
    
    private var isDone: Bool {
        completedCount + failedCount >= totalCount
    }
    
    private var currentTask: AssetUploadTask? {
        guard currentTaskIndex < tasks.count else { return nil }
        return tasks[currentTaskIndex]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Updating Plex Assets")
                .font(.headline)
            
            Text(mediaTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 400)
                
                HStack {
                    Text("\(completedCount + failedCount) / \(totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if failedCount > 0 {
                        Text("\(failedCount) failed")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .frame(width: 400)
            }
            
            // Current task
            if let current = currentTask {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently uploading:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        switch current.status {
                        case .uploading:
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        case .completed:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .failed:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        case .pending:
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                        
                        Text(current.displayName)
                            .font(.body)
                    }
                    
                    if let error = current.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                }
                .frame(width: 400, alignment: .leading)
                .padding(.vertical, 8)
            }
            
            // Scrollable task list
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(tasks) { task in
                        HStack {
                            switch task.status {
                            case .pending:
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            case .uploading:
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.7)
                            case .completed:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            case .failed:
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.displayName)
                                    .font(.caption)
                                
                                if let error = task.error {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .frame(width: 400)
            }
            .frame(height: 200)
            .border(Color.gray.opacity(0.2))
            
            // Buttons
            HStack(spacing: 12) {
                if !isDone {
                    Button("Cancel", action: onCancel)
                        .keyboardShortcut(.cancelAction)
                } else {
                    Spacer()
                    
                    Button("OK") {
                        isPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}

// MARK: - Preview

#Preview {
    PlexUploadProgress(
        mediaTitle: "Breaking Bad (2008)",
        tasks: .constant([
            AssetUploadTask(
                type: .showPoster,
                filePath: "/path/to/poster.png",
                ratingKey: "123",
                displayName: "Show Poster",
                status: .completed
            ),
            AssetUploadTask(
                type: .showBackdrop,
                filePath: "/path/to/backdrop.png",
                ratingKey: "123",
                displayName: "Show Backdrop",
                status: .uploading
            ),
            AssetUploadTask(
                type: .seasonPoster,
                filePath: "/path/to/season01.png",
                ratingKey: "124",
                displayName: "Season 01 Poster",
                status: .pending
            ),
            AssetUploadTask(
                type: .episodeTitleCard,
                filePath: "/path/to/S01E01.png",
                ratingKey: "125",
                displayName: "Season 01 Episode 01",
                status: .failed,
                error: "File not found"
            )
        ]),
        currentTaskIndex: .constant(1),
        isPresented: .constant(true),
        onCancel: {}
    )
}
