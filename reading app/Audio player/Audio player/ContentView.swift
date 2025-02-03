//
//  ContentView.swift
//  Audio player
//
//  Created by Chen Ge on 2/2/25.
//

import SwiftUI
import AVFoundation

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
                    Text(content.title)
                }
                .contextMenu {
                    Button(action: {
                        selectedContent = content
                        showingEditChapter = true
                    }) {
                        Label("编辑", systemImage: "pencil")
                    }
                }
            }
            .onDelete(perform: deleteChapter)
        }
        .navigationTitle(story.title)
        .toolbar {
            Button(action: {
                showingAddChapter = true
            }) {
                Image(systemName: "plus")
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
    
    func deleteChapter(at offsets: IndexSet) {
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index].contents.remove(atOffsets: offsets)
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
            Form {
                Section(header: Text("章节信息")) {
                    TextField("章节标题", text: $chapterTitle)
                }
                
                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
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
        let paragraphs = content.components(separatedBy: "\n")
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
                        .frame(height: 200)
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

struct StoryDetailView: View {
    let content: StoryContent
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isPlaying = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(content.paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .padding(.horizontal)
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
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                        Text(isPlaying ? "停止播放" : "开始播放")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle(content.title)
    }
    
    private func speakContent() {
        let allText = content.paragraphs.joined(separator: "。")
        let utterance = AVSpeechUtterance(string: allText)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN") // 设置中文语音
        utterance.rate = 0.5 // 设置语速
        utterance.pitchMultiplier = 1.0 // 设置音调
        utterance.volume = 1.0 // 设置音量
        
        speechSynthesizer.delegate = nil // 重置代理
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    ContentView()
}
