//
//  ContentView.swift
//  Audio player
//
//  Created by Chen Ge on 2/2/25.
//

import SwiftUI
import AVFoundation
import NaturalLanguage

struct StoryContent: Identifiable, Codable {
    let id = UUID()
    let title: String
    let paragraphs: [String]
}

struct Story: Identifiable, Codable {
    let id = UUID()
    let title: String
    var contents: [StoryContent]
}

struct ContentView: View {
    @AppStorage("savedStories") private var savedStoriesData: Data = Data()
    @State private var stories: [Story] = []
    @State private var showingAddStory = false
    
    private func loadStories() {
        if let decodedStories = try? JSONDecoder().decode([Story].self, from: savedStoriesData) {
            stories = decodedStories
        }
    }
    
    private func saveStories() {
        if let encodedStories = try? JSONEncoder().encode(stories) {
            savedStoriesData = encodedStories
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(stories) { story in
                    NavigationLink(destination: StoryContentsView(story: story, stories: $stories)) {
                        Text(story.title)
                    }
                }
                .onDelete(perform: deleteStory)
            }
            .navigationTitle("故事列表")
            .toolbar {
                Button(action: {
                    showingAddStory = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddStory) {
                AddStoryView(stories: $stories)
            }
        }
        .onAppear {
            loadStories()
        }
    }
    
    func deleteStory(at offsets: IndexSet) {
        stories.remove(atOffsets: offsets)
        saveStories()
    }
}

struct ModernStoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(story.title)
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(story.contents.count) 章")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let firstChapter = story.contents.first,
               let firstParagraph = firstChapter.paragraphs.first {
                Text(firstParagraph)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct StoryContentsView: View {
    let story: Story
    @Binding var stories: [Story]
    @State private var showingEditChapter = false
    @State private var selectedContent: StoryContent?
    @State private var showingAddChapter = false
    
    var body: some View {
        List {
            ForEach(story.contents) { content in
                NavigationLink(destination: StoryDetailView(content: content)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(content.title)
                            .font(.headline)
                        Text("\(content.paragraphs.count) 段")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        if let index = story.contents.firstIndex(where: { $0.id == content.id }) {
                            if let storyIndex = stories.firstIndex(where: { $0.id == story.id }) {
                                stories[storyIndex].contents.remove(at: index)
                            }
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    
                    Button {
                        selectedContent = content
                        showingEditChapter = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle(story.title)
        .toolbar {
            Button(action: { showingAddChapter = true }) {
                Label("添加章节", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingEditChapter) {
            if let content = selectedContent {
                EditChapterView(
                    stories: $stories,
                    storyTitle: story.title,
                    chapterTitle: content.title,
                    content: content.paragraphs.joined(separator: "\n")
                )
            }
        }
        .sheet(isPresented: $showingAddChapter) {
            AddStoryView(stories: $stories, presetStoryTitle: story.title)
        }
    }
}

struct StoryDetailView: View {
    let content: StoryContent
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isPlaying = false
    @State private var showingSettings = false
    @State private var speedValue: Double = 1.0  // 显示的速度值
    
    // 将显示速度转换为实际的播放速率
    private func displaySpeedToRate(_ speed: Double) -> Float {
        // AVSpeechUtterance.rate 范围是 0~1，0.5 是正常速度
        // 我们需要将 0.5x~2.0x 映射到合适的 rate 值
        switch speed {
        case 0.5: return 0.25   // 0.5x
        case 1.0: return 0.5    // 1.0x
        case 2.0: return 0.7    // 2.0x
        default:
            // 在范围内进行线性插值
            if speed < 1.0 {
                // 0.5x ~ 1.0x 的插值
                let progress = (speed - 0.5) / 0.5
                return Float(0.25 + (progress * 0.25))
            } else {
                // 1.0x ~ 2.0x 的插值
                let progress = (speed - 1.0) / 1.0
                return Float(0.5 + (progress * 0.2))
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(content.paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                        .lineSpacing(8)
                }
                
                VStack(spacing: 12) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "speedometer")
                            Text("播放速度：\(String(format: "%.1fx", speedValue))")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        if isPlaying {
                            speechSynthesizer.stopSpeaking(at: .immediate)
                        } else {
                            speakContent()
                        }
                        isPlaying.toggle()
                    }) {
                        HStack {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(isPlaying ? "暂停朗读" : "开始朗读")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle(content.title)
        .onDisappear {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isPlaying = false
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                Form {
                    Section(header: Text("播放速度")) {
                        VStack {
                            Slider(
                                value: $speedValue,
                                in: 0.5...2.0,
                                step: 0.1
                            )
                            HStack {
                                Text("0.5x")
                                Spacer()
                                Text(String(format: "%.1fx", speedValue))
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("2.0x")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("播放设置")
                .navigationBarItems(trailing: Button("完成") {
                    showingSettings = false
                })
            }
        }
    }
    
    private func speakContent() {
        let utterance = AVSpeechUtterance(string: content.paragraphs.joined(separator: "。"))
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = displaySpeedToRate(speedValue)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
}

struct EditChapterView: View {
    @Binding var stories: [Story]
    let storyTitle: String
    @State private var chapterTitle: String
    @State private var content: String
    @Environment(\.dismiss) var dismiss
    
    init(stories: Binding<[Story]>, storyTitle: String, chapterTitle: String, content: String) {
        self._stories = stories
        self.storyTitle = storyTitle
        self._chapterTitle = State(initialValue: chapterTitle)
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Section {
                        TextField("章节标题", text: $chapterTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    Section {
                        VStack(alignment: .leading) {
                            Text("内容")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 300)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("编辑章节")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveChanges()
                    dismiss()
                }
                .disabled(chapterTitle.isEmpty || content.isEmpty)
            )
        }
    }
    
    private func saveChanges() {
        let paragraphs = content
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let storyIndex = stories.firstIndex(where: { $0.title == storyTitle }),
           let chapterIndex = stories[storyIndex].contents.firstIndex(where: { $0.title == chapterTitle }) {
            stories[storyIndex].contents[chapterIndex] = StoryContent(
                title: chapterTitle,
                paragraphs: paragraphs
            )
        }
    }
}

struct AddStoryView: View {
    @Binding var stories: [Story]
    @Environment(\.dismiss) var dismiss
    @State private var storyTitle: String
    @State private var chapterTitle = ""
    @State private var content = ""
    
    init(stories: Binding<[Story]>, presetStoryTitle: String = "") {
        self._stories = stories
        self._storyTitle = State(initialValue: presetStoryTitle)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("故事信息")) {
                    TextField("故事标题", text: $storyTitle)
                }
                
                Section(header: Text("章节信息")) {
                    TextField("章节标题", text: $chapterTitle)
                }
                
                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                }
            }
            .navigationTitle(storyTitle.isEmpty ? "添加新故事" : "添加新章节")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveStory()
                    dismiss()
                }
                .disabled(storyTitle.isEmpty || chapterTitle.isEmpty || content.isEmpty)
            )
        }
    }
    
    private func saveStory() {
        let paragraphs = content.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let storyContent = StoryContent(
            title: chapterTitle,
            paragraphs: paragraphs
        )
        
        if let existingStoryIndex = stories.firstIndex(where: { $0.title == storyTitle }) {
            stories[existingStoryIndex].contents.append(storyContent)
        } else {
            let newStory = Story(
                title: storyTitle,
                contents: [storyContent]
            )
            stories.append(newStory)
        }
        
        // 保存到 UserDefaults
        if let encodedStories = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(encodedStories, forKey: "savedStories")
        }
    }
}

#Preview {
    ContentView()
}
