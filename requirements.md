"You are building an iOS SwiftUI app called 'Read & Recall'.

Requirements

Architecture

MVVM

SwiftUI

iOS 17+

Async/Await where needed

Environment objects for shared session data

Backend

Supabase for:

Authentication

Database

Storing books & vocab words

Offline caching optional

Data Models
Book

id

userId

title

author

coverImageUrl

createdAt

VocabWord

id

bookId

word

definition

synonyms

antonyms

exampleSentence

mastered

createdAt

Screens to Scaffold

Login / Create Account

Home Screen → list of books

Add Book → search by title, auto-fetch cover image

Book Detail → list of vocab words, add vocab button

Add Vocab → fetch definition, synonyms, antonyms, example sentence

All Vocab Words screen (global)

Study Section placeholder (flashcards + quizzes later)

Navigation

TabView for Home / All Words / Study Section

NavigationLink to detail screens

UI

Minimal placeholder UI, enough to build and run

Comment each file & function for clarity

GitHub

Scaffold should be ready to commit & push to your cloned repo

Do not implement dictionary API or Supabase logic yet — just scaffold the project so it builds in Xcode.”
