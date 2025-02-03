//
//  ContentView.swift
//  Audio player
//
//  Created by Chen Ge on 2/2/25.
//

import SwiftUI
import AVFoundation
import NaturalLanguage

struct StoryContent: Identifiable {
    let id = UUID()
    let title: String
    let paragraphs: [String]
}

struct Story: Identifiable {
    let id = UUID()
    let title: String
    var contents: [StoryContent]
}

struct ContentView: View {
    @State private var stories: [Story] = [
        Story(
            title: "小红帽",
            contents: [
                StoryContent(
                    title: "第一章：进入森林",
                    paragraphs: [
                        "从前，有一个可爱的小女孩，她总是戴着奶奶送给她的红色帽子。",
                        "有一天，妈妈让她去给生病的奶奶送食物。",
                        "小红帽踏上了穿过森林的旅程。"
                    ]
                ),
                StoryContent(
                    title: "第二章：遇见大灰狼",
                    paragraphs: [
                        "在森林里，小红帽遇到了狡猾的大灰狼。",
                        "大灰狼假装友好，询问她要去哪里。"
                    ]
                )
            ]
        )
    ]
    @State private var showingAddStory = false
    
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
    }
    
    func deleteStory(at offsets: IndexSet) {
        stories.remove(atOffsets: offsets)
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
    @State private var audioError: String?
    @State private var showingError = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(content.paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                        .lineSpacing(8)
                }
                
                Button(action: {
                    if isPlaying {
                        stopSpeaking()
                    } else {
                        startSpeaking()
                    }
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
                .padding()
            }
            .padding()
        }
        .navigationTitle(content.title)
        .onAppear {
            setupAudioSession()
        }
        .onDisappear {
            stopSpeaking()
        }
        .alert("播放错误", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(audioError ?? "未知错误")
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            audioError = "音频设置失败：\(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func startSpeaking() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true)
            
            let textToSpeak = content.paragraphs.joined(separator: "。")
            let utterance = AVSpeechUtterance(string: textToSpeak)
            
            // 尝试设置中文声音
            if let voice = AVSpeechSynthesisVoice(language: "zh-CN") {
                utterance.voice = voice
                print("使用中文声音：\(voice.language)")
            }
            
            // 设置语音参数
            utterance.rate = 0.4
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            speechSynthesizer.delegate = nil
            speechSynthesizer.speak(utterance)
            isPlaying = true
            
        } catch {
            audioError = "启动播放失败：\(error.localizedDescription)"
            showingError = true
            isPlaying = false
        }
    }
    
    private func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("停止音频会话失败：\(error.localizedDescription)")
        }
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
    }
}

#Preview {
    ContentView()
}
