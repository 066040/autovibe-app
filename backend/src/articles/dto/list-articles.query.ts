export class ListArticlesQuery {
  // filtreler
  publisherId?: string;
  sourceId?: string;
  language?: string;

  // arama (başlık + summary içinde)
  q?: string;

  // pagination
  cursor?: string; // Article.id
  limit?: string;  // query string -> number parse edeceğiz
}
